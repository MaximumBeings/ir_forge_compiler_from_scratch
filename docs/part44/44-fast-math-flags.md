# 44. Fast-Math Flags from the Compiler: What Reordering Is Allowed to Buy, and What It Did

![Mountain goats in space helmets on Mars](../assets/goats/ch-44.svg){ style="display:block;margin:0 auto;max-width:100%;height:auto;border-radius:6px" }

**What you will understand:** how a compiler can give LLVM permission to reorder floating-point arithmetic **one operation at a time**, why that is different from `-ffast-math`, and how to find out what the permission is worth. Chapter 37 showed that LLVM's vectorizer refuses to vectorize the dot-product loop of a matrix product (a floating-point sum) unless it is told the order of additions does not matter, and showed the permission as a `sed` experiment on the IR. This chapter makes the compiler do it: a small pass, `--mg-set-fastmath`, puts the `reassoc` and `contract` flags on the floating-point operations of a program, and `mgc --fast-math` runs it. Then it measures the result honestly: the flags change what the vectorizer decides and (with a fused multiply-add on the machine) the last bits of results, make one loop order 17% to 24% faster in a way that reproduced, and made no reproducible difference elsewhere. A negative control shows why one more flag, `nnan`, is deliberately **not** in the default: it turns a right answer into a wrong one.

**What you need to know first:** Chapter 37 (why the dot-product loop is not vectorized: "cannot prove it is safe to reorder floating-point operations") and Chapters 24 and 29 (loop orders; the softmax examples whose answers depend on NaN and infinity behaving as such).

!!! warning "This changes the numbers a program computes"
    Floating-point addition is not associative: `(a + b) + c` and `a + (b + c)` can differ in the last bit. `--fast-math` allows LLVM to choose the order, so a program built with it may print different low-order bits than one built without. It is **opt-in** (`mgc` does not turn it on), and the page measures how much it changed, which for the programs of this book was nothing visible at six printed digits. That is a statement about these programs, not about floating-point code in general.

!!! tip "Compile and run"
    ```sh
    cd docs/part44/code
    ./build.sh                                      # mg-opt of this chapter: Chapter 42's plus --mg-set-fastmath (a few minutes; needs mlir-18-tools, libmlir-18-dev, cmake)
    ./ir_and_remarks.sh > ir_and_remarks_out.txt    # the flags in the IR; what the loop vectorizer says (about 10 seconds)
    ./run_bench.sh > bench_out_1.txt                # matrix product with and without the flags, two loop orders, two clang settings (about 3 minutes); run it twice
    ./run_bench.sh > bench_out_2.txt && ./summarize.py > summary_out.txt
    ./semantics.py > semantics_out.txt              # all book examples at -O2, three settings (about 15 minutes)
    ./training_sensitivity.py > training_sensitivity_out.txt   # the 10-step training programs at -O2 (about 7 minutes)
    ./check_fastmath.py > check_fastmath_out.txt    # the checks of this page (about 15 seconds)
    ./mutation.py > mutation_out.txt                # 3 WRONG drivers and 5 WRONG passes the checker must catch (about 8 minutes: each pass mutant rebuilds mg-opt)
    cd ../../part15/code && ./run_lit.sh            # the whole test suite
    ```
    Every listing and output on this page comes from these commands. Times are from one 4-core machine (Xeon, 2.1 GHz, clang 18.1.3), pinned to one core.

!!! note "Why this page shows a mutation run, and why 'caught' is the wanted result"
    `mutation.py` writes broken versions of the pass and the driver and expects the checker to fail on each. "Caught" is good; "NOT CAUGHT" would be a gap. Nothing on this page is a failing test, with one exception that is the point of a section (the negative control, where a flag changes an answer and the page says so).

## What the flags are

LLVM's floating-point instructions can carry **fast-math flags**, one by one:

| flag | what the instruction is allowed to assume or do |
|---|---|
| `reassoc` | additions and multiplications may be regrouped: `(a + b) + c` may be computed as `a + (b + c)` |
| `contract` | a multiply followed by an add may be fused into one fused multiply-add, which rounds once instead of twice |
| `nnan` | arguments and results are never NaN (**if one is, the result is poison**: anything may happen) |
| `ninf` | the same for infinities |
| `nsz`, `arcp`, `afn` | the sign of zero does not matter; reciprocals may replace divisions; approximate functions are allowed |

`-ffast-math` on the command line sets all of them, and, as Chapter 37 showed, **does nothing at all to a `.ll` file**: the flags are properties of instructions, so they have to be in the IR. That is also why the right place to choose them is the compiler that writes the IR. Mountain Goat's default is the two that Chapter 37's experiment used, `reassoc` and `contract`, and nothing about NaN or infinity.

## The pass and the option

```cpp
--8<-- "docs/part44/code/SetFastMath.cpp"
```

The pass walks the module and, on every operation that implements MLIR's `ArithFastMathInterface` (`addf`, `subf`, `mulf`, `divf`, `negf`, the comparisons, ...), sets the `fastmath` attribute. `ArithToLLVM` carries the attribute into the LLVM dialect, and from there it becomes the flags on the LLVM instruction. The option `flags=` takes a comma-separated list; an unknown name is an error.

`mgc --fast-math` runs the pass after `--convert-mg-to-affine`; `mgc --fast-math=reassoc,nsz` chooses the flags. It is off unless asked for.

What the IR looks like (the product of two 64 × 64 matrices, ijk order, `mgc lib -O0`), and what LLVM's vectorizer says about its inner loop with `clang -O3 -march=sapphirerapids` (the CPU is pinned, as in Chapter 37, so this output does not depend on the machine that runs it):

```text
--8<-- "docs/part44/code/ir_and_remarks_out.txt"
```

- Without the flags: `fmul double`, `fadd double`; the vectorizer says **"cannot prove it is safe to reorder floating-point operations"** and does not vectorize the dot-product loop. This is Chapter 37's finding again, now from the compiler's own output.
- With `--fast-math`: `fmul reassoc contract double`, `fadd reassoc contract double`, and the loop **is vectorized**, for sizes known at compile time (width 4) and for sizes known only at run time (width 4, interleaved 4).
- The ikj order was already vectorized without the flags (it has no sum to reorder: Chapter 37), and the flags do not change that.

## What it is worth: speed

Does the vectorized dot product run faster? `run_bench.sh` builds the matrix product (sizes known at run time, 64 to 512) with and without the flags, in both loop orders, with `clang -O2` (baseline x86-64) and `clang -O3 -march=native` (which has fused multiply-add), pinned to one core, 7 trials per cell. Chapter 24's benchmark used small integers, so every sum was exact and no order could show; this one uses sines and cosines, so the rounding is real. Each result is compared with a reference computed in 80-bit `long double`, and with the same program built without the flags, bit by bit. The whole benchmark is run **twice**; the table gives the ratio of median times (flags over no flags: below 1 means the flags are faster) from each pass:

```text
--8<-- "docs/part44/code/summary_out.txt"
```

(The complete outputs are `bench_out_1.txt` and `bench_out_2.txt`.) What this says:

- **ikj with `-O3 -march=native`: 17% to 24% faster in the cells of both passes** (ratios 0.76 to 0.91, except N = 64 at 0.84 and 0.97). This is the one reproducible speed-up, and it comes from `contract`: with a fused multiply-add, the inner loop does one instruction where it did two. It is **not** a vectorization effect (this loop was vectorized already).
- **Everything else is noise-sized and inconsistent**: ijk and ikj at `-O2` between 0.88 and 1.39; ijk with `-march=native` between 0.99 and 1.69 (that is *slower* at N = 64, in both passes). In an earlier, single run of this experiment, ijk at `-O2` looked 28% faster at N = 512 (326 ms against 459 ms); the two passes above do not reproduce that (1.02 and 1.19), so I treat it as noise and not as a result.
- **So the vectorized dot product did not make ijk faster.** Why not is partly understood: with sizes known at run time, LLVM guards the vectorized loop with a run-time check that the memref's stride is 1, and the ijk loop reads the second matrix down a column (stride N), so the check fails and the scalar path executes. Evidence: at `-O2` the results are **bit-identical** to the build without the flags in every element of every size (a vector sum in another order would change bits), and the object file contains packed adds (`addpd`) that are not executed. That does not explain why the timings still differ between builds at all, and I did not look further.

### Does it change the numbers?

The same table's last columns: at `-O2` (no fused multiply-add) **no element differs by a single bit**; with `-march=native`, **88% to 89% of the elements differ in their bits** (233,864 of 262,144 at N = 512), because `contract` fuses the multiply and the add and rounds once. The largest error against the `long double` reference stays at the same size, a few times 10⁻¹⁷ relative to the scale of the dot product, and is not larger with the flags (8.1 × 10⁻¹⁷ against 9.3 × 10⁻¹⁷ at N = 512). A fused multiply-add rounds once instead of twice, so it is, if anything, slightly more accurate. Different bits, same quality: but different bits are exactly what a program that compares outputs bit for bit, or a chaotic training run, can notice.

## Do the book's programs print different numbers?

`semantics.py` compiles every example of the book that the front end accepts and that has under 400 lines (109 programs) at `-O2` three ways and compares the printed numbers:

```text
--8<-- "docs/part44/code/semantics_out.txt"
```

All 109 print the same with the default flags. They also print the same with `nnan,ninf` added. **That second line is not evidence that `nnan` is safe.** It means these programs do not contain a computation on which the flag changes an answer in a way LLVM exploited. The next section builds one.

### The negative control: why `nnan` is not in the default

Chapter 29's naive softmax of huge scores is NaN (infinity divided by infinity). A NaN is not `>=` itself, so `ge(p, p)` for a NaN `p` must be 0:

```text
--8<-- "docs/part44/code/examples/01_nan_compare.mg"
```

The checker's line for it:

```text
  ok   ge(p, p) for a NaN p at -O2: plain [[0,0,0]], reassoc+contract [[0,0,0]], with nnan [[1,1,1]] (the last is WRONG, and is why nnan is not a default)
```

At `-O2`: no flags 0 (right), `reassoc,contract` 0 (right), `reassoc,contract,nnan` **1 (wrong)**. The flag told LLVM that `p` is never NaN, so `p >= p` was folded to true. At `-O0` it prints 0 in every setting; the wrong answer needs the optimizer. That is the whole reason the default is only `reassoc` and `contract`: those two change rounding; `nnan` and `ninf` can change **which answer** the program gives, and Mountain Goat's softmax examples exist to show that NaN and infinity are results a program may legitimately compute. The 109-program check above would not have caught this: the program that exposes it had to be written.

## Does it change a training run?

Chapter 35 found its 200-step training run chaotic: a change in the last bit grows until the printed checkpoints disagree. A flag that changes the last bit of every sum is a direct test of that. `training_sensitivity.py` compiles the 10-step training programs of Chapters 35 and 36 at `-O2`, plain and with `--fast-math`, for the baseline CPU and with `-march=native`, and compares everything they print:

```text
--8<-- "docs/part44/code/training_sensitivity_out.txt"
```

All four pairs print identical numbers at six digits. **That does not show the bits are the same** (I printed no more than six digits, and with `-march=native` the matrix-product test above shows the bits do change), and 10 steps is far from where Chapter 35's chaos appears. The 200-step experiment I wanted is **not** here: at `-O2`, `clang` was still compiling the 200-step Chapter 35 program after 29 minutes and I stopped it. (That also bounds Chapter 43's compile-time claim for `-O2`: it was measured on the 10-step programs only.) So the honest statement is: the flag did not change a 10-step run's printed output; whether it changes a 200-step run is **not established**.

## Tests

One new `lit` file `test/fastmath44/check.mlir` (the suite is now 156 tests). The checker:

1. **The pass:** every floating-point operation gets `fastmath<reassoc,contract>`, the integer addition gets nothing, the unprocessed file gets nothing; `flags=reassoc,nsz` gives exactly those; an unknown flag is an error with a message.
2. **The driver:** by default the LLVM IR of the self-attention example has 18 `fadd`/`fsub`/`fmul`/`fdiv`, none with a flag; with `--fast-math` all 18 carry `reassoc contract`; with `--fast-math=reassoc` all carry `reassoc` and nothing else.
3. **The vectorizer:** the ijk product is not vectorized without the flags (and the remark is the one about reordering), and is vectorized with them, for static and dynamic sizes.
4. **The default is safe on the book's programs:** every sixth example prints the same at `-O2` with `--fast-math`.
5. **The negative control:** `ge(p, p)` prints 0, 0 and 1 for plain, `reassoc,contract` and `nnan`.

```text
--8<-- "docs/part44/code/check_fastmath_out.txt"
```

### Are the checks good enough? Eight wrong builds.

```text
--8<-- "docs/part44/code/mutation_out.txt"
```

All eight are caught, and which check catches which is informative:

- A default that includes `nnan` is caught by the negative control as well as by the flag check: it is the mutant that makes the wrong answer appear.
- A driver whose `--fast-math=FLAGS` ignores FLAGS is caught by the `reassoc`-only check; so is a pass that ignores its option.
- A pass that skips multiplications and a default that lacks `contract` are caught by the first check because it looks at every operation and at the exact flag list.
- An unknown flag silently ignored is caught **only** by the check that asks for the error message.

## Limits and what is not established

- **The speed-up is one case**: ikj with `-O3 -march=native`, 17% to 24%, from fused multiply-add. The dot-product vectorization that motivated the chapter gave **no reproducible speed-up** here, probably because of the run-time stride check (not shown to be the whole story). Static sizes were not benchmarked.
- **One machine**, pinned to one core, 7 trials per cell, two passes. Ratios between 0.9 and 1.4 in the noise-sized cells show how much the machine itself moves.
- **Bits change with `-march=native`** (88% to 89% of the matrix-product results). Whether that matters is up to the program; the book's programs printed the same at six digits, which is weaker than "the same".
- **The 200-step training run was not tested** (compile time at `-O2` over 29 minutes, stopped); chaos is therefore untested with this flag.
- **The negative control is one program.** It shows `nnan` can change an answer, not how often; the flags `ninf`, `nsz`, `arcp` and `afn` were not studied one by one.
- **The pass sets the same flags on every floating-point operation** of the module. It does not choose per loop or per operation, which LLVM allows and a real compiler might want (for example, only on sums).
- **`math` operations (`exp`, `sqrt`, `log`) are not touched**: they become library calls, and the `math` dialect's own flags are not set here.

## Reproducing

```sh
cd docs/part44/code && ./build.sh
./ir_and_remarks.sh > ir_and_remarks_out.txt
./run_bench.sh > bench_out_1.txt && ./run_bench.sh > bench_out_2.txt && ./summarize.py > summary_out.txt
./semantics.py > semantics_out.txt && ./training_sensitivity.py > training_sensitivity_out.txt
./check_fastmath.py > check_fastmath_out.txt && ./mutation.py > mutation_out.txt
cd ../../part15/code && ./run_lit.sh          # 156 tests
```

## Chapter summary

- LLVM fast-math flags are per instruction, and `-ffast-math` does nothing to a `.ll` file, so the compiler that writes the IR is the place to choose them. `--mg-set-fastmath` puts `reassoc` and `contract` on every floating-point operation; `mgc --fast-math` runs it; it is off by default.
- With the flags, LLVM vectorizes the ijk dot-product loop it refused to before (Chapter 37, now from the compiler's own output).
- The only reproducible speed-up was ikj with a fused multiply-add: 17% to 24%. ijk did not get faster, plausibly because the vectorized path is guarded by a stride check that column access fails.
- At `-O2` the results are bit-identical; with `-march=native`, 88% to 89% of results differ in their bits and the error against a long-double reference is not larger.
- 109 book programs and the 10-step training programs print the same numbers. That is not proof of safety: `nnan` flips `ge(p, p)` for a NaN `p` from 0 to 1 at `-O2`, which is why it is not a default.
- Eight broken builds are caught. The 200-step training run was not tested.

## Self-check questions

Each answer is collapsed; try the question first.

1. Why did Chapter 37's `-ffast-math` experiment on a `.ll` file do nothing, and what does this chapter do instead?

    ??? note "Answer"
        Fast-math flags are properties of individual LLVM instructions. `-ffast-math` is an option of the C front end of clang that sets them on the instructions it generates from C; a `.ll` file already contains the instructions and clang does not rewrite them. The compiler that writes the IR has to put the flags on the operations, which is what `--mg-set-fastmath` does.

2. What do `reassoc` and `contract` allow, and why those two and not `-ffast-math`'s whole set?

    ??? note "Answer"
        `reassoc` allows regrouping sums and products, which is what lets the dot-product loop be vectorized; `contract` allows a multiply and an add to become one fused multiply-add. Both change rounding. `nnan` and `ninf` change the meaning of NaN and infinity, which Mountain Goat's softmax examples rely on; the negative control shows `nnan` turning `ge(p, p)` for a NaN `p` from 0 to 1.

3. The 109 book programs print the same with `nnan,ninf`. Why is that not evidence the flags are safe?

    ??? note "Answer"
        It only shows that none of those programs has a computation on which LLVM exploited the assumption. The negative control, written specifically to depend on NaN behaviour, changes its answer at `-O2`. A test that passes on programs that never exercise the risk says nothing about the risk.

4. Why did the vectorized ijk loop not run faster, and what is the evidence?

    ??? note "Answer"
        With sizes known at run time, LLVM guards the vectorized loop with a check that the stride is 1; ijk reads the second matrix down a column, so the check fails and the scalar loop runs. At `-O2` every result element is bit-identical with and without the flags (a vectorized sum in another order would differ), although the object file contains packed adds. This does not explain the remaining timing differences, and static sizes were not benchmarked.

5. What reproduced as a speed-up, and why?

    ??? note "Answer"
        ikj at `-O3 -march=native`: 17% to 24% faster in both passes (ratios 0.76 to 0.91, with N = 64 at 0.84 and 0.97). The cause is `contract`: the machine has a fused multiply-add, and the inner loop does one instruction where it did two. The loop was already vectorized, so it is not about vectorization.

6. With `-march=native`, 88% to 89% of the matrix-product results differ in their bits with the flags. Is the answer worse?

    ??? note "Answer"
        Not by the measure used: the largest error against an 80-bit reference stays at the same size (8.1 × 10⁻¹⁷ against 9.3 × 10⁻¹⁷ at N = 512), and a fused multiply-add rounds once instead of twice. The bits are different, which matters for a program that compares outputs exactly or amplifies tiny differences, as Chapter 35's chaotic run does.

7. Name three things this chapter does not establish.

    ??? note "Answer"
        Any of: whether the flag changes a 200-step training run (the `-O2` compile did not finish in 29 minutes); the speed for statically known sizes; how often `nnan` changes an answer (one program only); the effect of the other flags (`ninf`, `nsz`, `arcp`, `afn`); why the timings of the ijk builds differ at all when their results are bit-identical; per-operation instead of module-wide flags.
