# 37. Inside the LLVM Stage: Reading the IR, and Why a Loop Does or Does Not Vectorize

![Mountain goats in space helmets on Titania, a moon of Uranus](../assets/goats/ch-37.svg){ style="display:block;margin:0 auto;max-width:100%;height:auto;border-radius:6px" }

**What you will understand:** what happens to a Mountain Goat program after MLIR hands it to LLVM. Every chapter since Chapter 5 has ended with "lowered to LLVM IR, then clang makes the executable", and none has opened that stage. This chapter opens it. You will **read** the LLVM IR that `mgc` writes; watch LLVM's optimizer, `opt`, change a matrix product **pass by pass**; ask the loop vectorizer **why** it did or did not vectorize a loop (Chapter 23 counted vector instructions and Chapter 24 got a 3× to 11× speedup from a loop-order change, and neither said why); read the **assembly** of the two inner loops; and ask `llvm-mca`, a model of the CPU's pipeline, what it predicts. The chapter ends with two corrections to its own first experiments and one place where the model predicts a speedup that the measurement refuses to show.

**What you need to know first:** Chapter 5 (the lowering to the LLVM dialect and IR), Chapter 23 (the benchmark, `-O3 -march=native`) and Chapter 24 (the `ikj` loop order). **No new compiler operation** is needed and the compiler is unchanged: the programs run on Chapter 32's `mgc`, and the tools are LLVM 18's own: `opt-18`, `clang-18`, `llvm-mca-18`.

!!! tip "Compile and run"
    ```sh
    cd docs/part32/code && ./build.sh                 # once: the newest compiler (this chapter adds nothing to it)
    cd ../../part37/code
    ./stages.sh > stages_out.txt                      # the files mgc writes on the way to machine code, for the smallest program and for the matrix product
    ./walk.sh > walk_out.txt                          # opt, pass by pass, on the matrix product's IR
    ./remarks.sh > remarks_out.txt                    # the loop vectorizer's decisions and reasons
    ./ops_table.sh > ops_table_out.txt                # which of Mountain Goat's operations vectorize (instruction counts)
    ./mca.py > mca_out.txt; ./mca.py --loops > loops_out.txt   # llvm-mca's prediction, and the assembly of the two inner loops
    ./cpu_dependence.py > cpu_dependence_out.txt      # the same IR compiled for four different CPUs (compile only)
    ./variants.sh > variants_out.txt; ./summarize_variants.py > variants_summary.txt   # the measurement: 3 passes of the Chapter 24 benchmark (about 2 minutes)
    ./check_llvm.py > check_llvm_out.txt              # every claim on this page, tested for the pinned CPU (about 3 seconds)
    ./claims_mutation.py > claims_mutation_out.txt    # six WRONG inputs the checker must catch (about 20 seconds)
    cd ../../part15/code && ./run_lit.sh              # the whole test suite
    ```
    Every listing and output on this page comes from these commands.

!!! note "Why this page shows FAIL lines and 'not vectorized' remarks, and why that is good"
    "Loop not vectorized" is not an error: it is LLVM explaining a decision, and the explanation is the subject of the chapter. The `claims_mutation.py` output is a negative control: deliberately wrong inputs fed to the checker, where "caught" is the wanted result and "NOT CAUGHT" would be a gap.

## Where LLVM sits in `mgc`

`mgc` is a chain of real tools (its header says so). With `MGC_KEEP=dir` it keeps the file each stage writes. For the smallest program (`examples/01_add2x2.mg`, `a + b` on 2 × 2 matrices) and for the 64 × 64 matrix product (`examples/02_matmul64.mg`), the stages and their sizes are:

```text
--8<-- "docs/part37/code/stages_out.txt:1:15"
```

`mgfront.py` writes the `.mlir` (the `mg` dialect), `mg-opt --convert-mg-to-affine` writes the `.affine.mlir` (loops, loads, stores), `mg-opt` with the lowering passes writes the `.llvm.mlir` (the LLVM *dialect*: MLIR's own copy of LLVM's instructions), and `mlir-translate` writes the `.ll`, which **is** LLVM IR: the text format LLVM's tools read. From here on nothing is MLIR: `opt` optimizes the `.ll`, and `clang` turns it into assembly and an executable. (The two loop orders have the same line counts: only the order of the three loops inside differs.)

## Reading the IR

Here is the whole LLVM IR of the 2 × 2 add. Take it in four parts:

```text
--8<-- "docs/part37/code/stages_out.txt:40:113"
```

1. **The descriptors (the long run of `insertvalue`).** Each matrix arrives as seven separate arguments (`ptr %0, ptr %1, i64 %2, …`: allocated pointer, aligned pointer, offset, two sizes, two strides, Chapter 1's memref calling convention), and the first 14 instructions pack them into two `{ ptr, ptr, i64, [2 x i64], [2 x i64] }` values, the memref descriptors (seven more build the result's). Almost all of this is dead weight: only each argument's aligned pointer is read later (`extractvalue … 1`). It is the first thing the optimizer will delete.
2. **The allocation:** `call ptr @malloc(i64 ptrtoint (ptr getelementptr (double, ptr null, i32 4) to i64))`, that is `malloc(4 * sizeof(double))` for the 2 × 2 result (the `getelementptr … null` is the idiom for `sizeof`). The generated code never frees what it allocates.
3. **The loops (`phi`, `icmp`, `br`).** LLVM IR is in *static single assignment* form: every name is assigned once. A loop counter that changes is therefore a `phi`: `%38 = phi i64 [ %61, %60 ], [ 0, %14 ]` means "if control came from block `%60`, take `%61` (the incremented value), if from `%14`, take 0". The two nested loops are the two `phi`s, `icmp slt` the bound test, `br i1` the conditional branch.
4. **The body:** `mul`/`add` compute the flat index `i * 2 + j`, `getelementptr double, ptr %45, i64 %47` is the address of that element (LLVM's pointer arithmetic: it never reads memory), `load double`, `fadd double %49, %54`, `store double`. The `fadd` carries **no flags**: that detail matters twice below.

The 64 × 64 matrix product (`02_matmul64.mg`) has the same pieces plus a second loop nest for the zero fill and a three-deep nest whose body is `load` the running sum from the result, `load` a, `load` b, `fmul`, `fadd`, `store` the sum back (every iteration goes through memory).

## What `opt` does, pass by pass

`opt` runs *passes* over the IR. `walk.sh` runs a growing list of the standard ones on the matrix product and counts what is left (instructions, basic blocks, and lines that mention a vector of doubles `<N x double>`). The target (`-mtriple`, `-mcpu`) must be given: without it `opt` does not know which vector instructions exist, and the vectorizer did nothing (the first version of this script forgot, and every row showed 0 vector lines).

```text
--8<-- "docs/part37/code/walk_out.txt:1:21"
```

- **`instcombine`, `simplifycfg`:** 77 → 57 instructions. This is the dead descriptor packing going away, and constants folded.
- **`loop-rotate`, `licm`, `indvars`:** the loops are put in canonical form; the next table row shows no change in size, which is the point of canonical form: it is what the vectorizer needs.
- **`loop-vectorize`:** the ikj order grows from 56 to **106** instructions and gains vector arithmetic (the vector body, the scalar remainder loop, and the run-time checks that guard them). The ijk order grows to 69 instructions with **one** line mentioning vector doubles. Which line? `store <4 x double> zeroinitializer`: the *zero-fill* loop was vectorized, and the product's own loop was not (the last lines of the second excerpt below print it).
- **`loop-unroll`:** both orders unroll their inner loop (180 and 377 instructions).
- **the whole `-O3` pipeline** goes further than the list. The same file shows the ijk order's result:

```text
--8<-- "docs/part37/code/walk_out.txt:23:41"
```

  The `malloc` and the zero-fill loop became **one `calloc`** (the loop-idiom pass recognizes "allocate, then fill with zeros"). The running sum is no longer loaded and stored every iteration: `%.promoted = load double` before the loop, `phi double [ %.promoted, … ]` inside it, and a single `store` (17 loads and 1 store in the whole function): LICM's **scalar promotion** moved the accumulator into a register. The inner loop is unrolled eight times into a **chain**: `%28 = fadd double %21, %27`, then `%36 = fadd double %28, %35`, each addition waiting for the previous one. Remember this chain: it is the next section's subject, and the backend's.

## Why the ijk loop is not vectorized, and what the permission costs

`remarks.sh` asks clang's loop vectorizer for its decisions (`-Rpass`, `-Rpass-missed`, `-Rpass-analysis`):

```text
--8<-- "docs/part37/code/remarks_out.txt"
```

For the default `ijk` order the vectorizer says, with and without `-march=sapphirerapids` (the CPU of the machine these pages were produced on; the scripts pin it, see "Is this specific to one CPU?" below):

> loop not vectorized: cannot prove it is safe to reorder floating-point operations

For `ikj` it says `vectorized loop` (width 2 on plain x86-64, which has 128-bit SSE2 registers; width 4 with `-march=sapphirerapids`, which allows 256-bit AVX registers).

**Why.** The `ijk` inner loop is a *reduction*: `sum = sum + a[i][k] * b[k][j]`. A vectorized version adds four partial sums and combines them at the end, which adds the numbers in a different order, and floating-point addition is **not associative**: `(a + b) + c` can differ from `a + (b + c)`. LLVM must produce exactly what the program says unless it is told reordering is allowed. The `ikj` loop has no reduction: each iteration `c[i][j] += x * b[k][j]` updates a different element, so the iterations are independent and vectorizing them reorders nothing.

**The experiment: give the permission, and see what it buys.** Fast-math permission is a *flag on each instruction in the IR*: `fadd reassoc double …` means "this addition may be reassociated". Add it to every `fadd` of the ijk IR (`sed 's/fadd double/fadd reassoc double/'`): the vectorizer now says `vectorized loop (vectorization width: 4 …)`. The ijk loop vectorizes. Is it faster? `variants.sh` builds Chapter 24's benchmark (dynamic sizes) four ways and times each at N = 256 and 512 (pinned to one core, three passes, each result checked against a reference; the table is `summarize_variants.py`'s):

```text
--8<-- "docs/part37/code/variants_summary.txt"
```

- **Vectorizing the ijk loop does not make it faster.** Mean over three passes: 2.28 against 2.23 GFLOP/s at N = 256 and 0.64 against 0.67 at N = 512, with each pair's three passes overlapping. The vectorizer's permission was not what kept ijk slow.
- **The loop order is.** `ikj` is 4.6× faster than `ijk` at N = 256 and 10.9× at N = 512, with or without the permission (which `ikj` does not need).
- **Why the vectorized ijk is no faster.** `b[k][j]` walks *down a column*: consecutive `k` are a whole row apart in memory, so the vector must be **gathered** one element at a time (the assembly of the vectorized ijk has 16 `vgather` instructions; the ikj assembly has none: `check_llvm_out.txt`). Gathers move the same strided data a scalar loop would, so the reduction's permission buys no bandwidth. This is an inference from the instruction counts and the timings; **no hardware counters were read** (cache misses were not measured), so "memory-bound" is the explanation that fits, not a measured fact.

**A correction.** The first version of this experiment used clang's `-ffast-math` option, the way a C programmer would. It changed nothing: `remarks.sh` shows the same "cannot prove it is safe" remark and the assembly with and without the flag is **byte for byte identical** (`cmp` says so). The reason is that `-ffast-math` tells the *front end* which flags to put on the instructions it generates from C or C++ source; a `.ll` file already has its instructions, with no flags, and clang does not rewrite them. The permission has to be in the IR, which is where Mountain Goat would have to put it if it ever offered it (its lowering emits plain `arith.addf`; MLIR can attach `fastmath<reassoc>` to it, which was not done here).

## Reading the assembly

Here are the two inner loops from `clang -O3 -march=sapphirerapids` (`mca.py --loops`), the ijk order's first, then ikj's:

```text
--8<-- "docs/part37/code/loops_out.txt:3:55"
```

- **ijk (34 instructions, 8 multiply-adds):** eight `vmulsd`/`vaddsd` pairs (`sd` = scalar double). Every `vaddsd` reads and writes `%xmm0`: the additions form a **dependency chain**, each waiting for the last, exactly the chain seen in the IR. The loads of `b` step by `%r10` (the row length) between multiplies: the column walk. There are no fused multiply-adds: the `vmulsd` and `vaddsd` are separate.
- **ikj (15 instructions, 16 multiply-adds):** four `vmulpd` and four `vaddpd` on `%ymm` registers (`pd` = packed double, `ymm` = 256 bits = 4 doubles), so 16 multiply-adds per iteration, with memory operands folded in and four stores. The four vectors are independent: no chain. (This CPU has 512-bit registers; clang 18 chose 256-bit ones. Why was not investigated.)
- **Neither uses `vfmadd`.** A fused multiply-add computes `a * b + c` in one instruction with one rounding, which gives a *different* result from a multiply followed by an add, so LLVM needs permission: the `contract` flag on the `fmul` and the `fadd`. C compilers grant it by default in C (`-ffp-contract=on`), which is why you rarely see this; our IR has no flags. Adding `contract` (same `sed` trick) turns the ikj loop's multiply and add into `vfmadd` instructions (16 in the static 64 × 64 version, `check_llvm_out.txt`), and `variants.sh` measures them: ikj with `contract` is 7.3 → 9.1 GFLOP/s at N = 512 (all three of its passes, 8.24 to 9.55, are above all three of plain ikj's, 7.16 to 7.36) and 10.3 → 11.1 at N = 256 (overlapping passes: **no clear gain** there). That is about +24% at N = 512 on this machine.

## What `llvm-mca` predicts, and where the prediction fails

`llvm-mca` takes a block of assembly and simulates how the CPU's pipeline would execute it, many times, and reports cycles. It models the **core** (instruction latencies, issue ports, dispatch width). It assumes every load hits the L1 cache: **it does not model the memory system.** `mca.py` runs each variant's hot loop through it (`-mcpu=sapphirerapids`) and divides by the multiply-adds per iteration:

```text
--8<-- "docs/part37/code/mca_out.txt"
```

- **The ijk loop costs 3.02 cycles per multiply-add**: the chain of eight dependent additions is the limit. **The ikj loop costs 0.29**: ten times less.
- **`reassoc` is predicted to be a big win for ijk: 0.20 cycles per multiply-add, 15 times better.** The model sees the chain broken into independent vector adds. **The measurement did not show it** (previous section: 0.64 against 0.67 GFLOP/s). The model and the measurement disagree, and the disagreement is informative: `llvm-mca` is blind to the strided column walk, which is the bottleneck. This is the page's cleanest example of what a core model can and cannot say: it correctly ranks ikj above ijk (predicted 10.4×, measured 4.6× at N = 256 and 10.9× at N = 512), and it incorrectly predicts a large gain from vectorizing ijk.
- `contract` is predicted to help ikj a little (0.29 → 0.25 cycles per multiply-add, 14%): the same direction as the measurement, at a smaller size than the +24% measured at N = 512.

(One repair along the way: the first version of `mca.py` picked a loop that contained the inner loops, so it counted too many multiplies; and weighed instructions, not lanes, so it preferred the unrolled scalar loop to the vectorized one. It now takes innermost loops only, ranked by multiply-adds per iteration.)

## Which Mountain Goat operations vectorize?

`ops_table.sh` compiles each one-operation program in `ops/` on 64 × 64 matrices with `clang -O3 -march=sapphirerapids` and counts, in the assembly, packed arithmetic instructions (`vaddpd`, `vmulpd`, `vmaxpd`, `vsqrtpd`, `vcmppd`, …: four doubles at once), scalar ones (`vaddsd`, …), gathers, and library calls. It counts **instructions**; it says whether the compiler vectorized, not whether that was faster.

```text
--8<-- "docs/part37/code/ops_table_out.txt"
```

- **The element-wise operations** (`add`, `hadamard` (a * b), `scale`, `relu`, `sqrt`, `ge`, and the broadcast add) are all vectorized with no scalar arithmetic left. (`relu`'s count is 32 against 16 for the others; its instruction mix was not examined. `bcast_add` also calls `memcpy`.)
- **`exp` and `log` are not vectorized**: no packed arithmetic at all, and the assembly **calls the C library's `exp` and `log`** once per element (clang has no vector version of them to call). Softmax (Chapter 29), and so every attention head in Chapters 30 to 36, uses `exp`.
- **`transpose` has no arithmetic**: it is 16 gathers and moves.
- **The row reductions** (`row_sum`, `row_mean`, `row_max`) have **no scalar adds** and use 64 gathers each, which is the opposite of what the matrix product's reduction did. The reason is not established here: the assembly (64 gathers feeding 64 packed adds, no scalar adds) is consistent with LLVM keeping each row's addition order exactly as written and vectorizing **across rows** (four rows' running sums in one register, gathered from four rows), which reorders nothing, but the transformation was not identified (the IR was not read for it). The same permission question does not arise when each lane is a different row. `col_sum` adds whole rows, so it vectorizes without gathers.

## Is this specific to one CPU? Yes, in the details

The first CI run of this chapter's test **failed**, on a different CPU from the one used here, while every other test passed. The compiler's choices depend on the target CPU, so the scripts now pin it (`sapphirerapids`; `CPU=native ./walk.sh` overrides) and the chapter's claims are claims *about that target*. `cpu_dependence.py` compiles the same IR for four CPUs (compilation only: nothing is run) and shows how much changes:

```text
--8<-- "docs/part37/code/cpu_dependence_out.txt"
```

- **What does not depend on the CPU, in these four:** `ijk` is not vectorized, `ikj` is (width 4), and `ijk` with the `reassoc` flag is (width 4). The reduction story holds everywhere tried.
- **What does:** the **gathers**. On `sapphirerapids` and `skylake-avx512` the vectorized ijk loop and `row_sum` use `vgather` instructions (16 and 64). On `haswell` and `znver3` there are **none**, although both CPUs have AVX2 and the vectorizer still vectorizes: it fills the vectors with scalar loads instead (LLVM treats gathers as slow on those CPUs; the exact mechanism in the assembly was not read for them). So the chapter's inference "the vectorized ijk is no faster because it gathers" was tested only on the Intel targets and the measurement was made on an Intel machine; for the other two CPUs only the instruction mix, not a timing, is known.
- **The fused multiply-add count differs** (16, 16, 16 and 64 `vfmadd` for the same loop), and so do `llvm-mca`'s cycles per multiply-add (ijk 3.0 to 4.0, ijk with `reassoc` 0.20 to 0.32, ikj 0.29 to 0.45): the *ranking* is the same on all four (ikj and reassoc'd ijk far below ijk), the numbers are not.

## Tests

Two new `lit` files in `test/llvm37/` (the suite is now 146 tests; no `verifiers` or `ir` test because no compiler operation was added):

| Test | What it checks |
|---|---|
| `examples` | the three programs compile to the expected `mg` operation; every one of the fourteen one-operation programs in `ops/` compiles |
| `claims` | `check_llvm.py`, below (about 3 seconds) |

`check_llvm.py` runs the tools and tests the claims, in five groups: (1) the IR's shape (one `fadd`, one `malloc`, two loop counters for the add; a `fmul` and a `fadd` in the product); (2) `opt`: after `loop-vectorize` ikj has a vector `fmul` and ijk has only the vector store of zeros; the whole `-O3` pipeline leaves one `calloc`, no `malloc`, a promoted accumulator and no vector multiply; (3) the remarks: ijk's "cannot prove it is safe", ikj's "vectorized loop", ijk with `reassoc` vectorized **and gathering** (16 `vgather`s, ikj none), and `-ffast-math` leaving the assembly identical; (4) the operations: `add` packed and not scalar, `exp` a library call and not packed, `row_sum` gathers, `transpose` no arithmetic; (5) the backend: ikj has no `vfmadd` and has them with `contract`, and `llvm-mca` puts ijk above five times ikj per multiply-add and `reassoc` below a third of ijk.

```text
--8<-- "docs/part37/code/check_llvm_out.txt"
```

### Are the checks good enough? Feed it six wrong inputs.

`claims_mutation.py` changes one input at a time (the environment variables `CHK_*` of the checker) and expects the checker to fail:

```text
--8<-- "docs/part37/code/claims_mutation_out.txt"
```

All six are caught, each by the checks that should depend on the input that was broken: the `ijk` program built in the other order fails the three ijk claims; leaving out `reassoc` fails the "vectorized" claim and the gather claim; replacing `-ffast-math` with `-O1` (a flag that does change the assembly) fails the byte-for-byte claim; `nsz` in place of `contract` fails the fused-multiply-add claim; `opt` without a target fails both vectorization claims. One result was a surprise and is worth reading: **removing AVX (`-mno-avx`)** fails five checks, including "ijk with `reassoc` is vectorized": with only SSE2 the vectorizer declines the strided reduction loop that it vectorizes with AVX (the reason was not investigated; the cost model or the missing gather instructions are the candidates). The practical lesson is that **these claims describe the `sapphirerapids` target** (the checks pin `sapphirerapids`), and would need different expected values for other targets, as the CPU section shows.

The full suite:

```text
--8<-- "docs/part15/code/run_out_146.txt"
```

## Limits and what is not established

- **One machine, one LLVM.** An Intel Xeon (`sapphirerapids` in LLVM's naming) at 2.1 GHz, LLVM 18.1.3, clang 18.1.3. Vector widths, the choice of 256-bit registers, `llvm-mca`'s numbers and the benchmark all depend on them. The checks pin `sapphirerapids`; the CPU section shows that gathers, fused multiply-adds and `llvm-mca` numbers differ on other targets.
- **"Memory-bound" is inferred, not measured.** The explanation for the vectorized ijk being no faster is gathers in the assembly plus unchanged timings; no hardware counters (cache misses, TLB misses) were read.
- **The benchmark is the Chapter 24 harness with its noise.** Three passes, one pinned core, spreads of up to about 30% between passes at N = 256 (for example ikj's 9.2 to 11.7 GFLOP/s); the contract result at N = 512 is consistent across passes, the one at N = 256 is not.
- **`llvm-mca` is a core model.** It ignores the memory system and assumes perfect branch prediction; the page shows it ranking correctly and over-predicting the gain from vectorizing ijk.
- **`-ffast-math` was shown to be a no-op on `.ll` files, but Mountain Goat does not generate the flags.** Adding `reassoc` or `contract` to the generated IR was done by text substitution in the experiments; it was **not** added to the compiler, and the results of such programs would no longer be bit-for-bit those of Chapter 24's loop order (`reassoc` and `contract` change rounding).
- **The row reductions' mechanism is not identified** (see the operations section).
- **Only the matrix product and fourteen single operations were looked at,** at 64 × 64; the training programs of Chapters 35 and 36, whose compile time was long, were not studied (where `mg-opt` spends it is not known).
- **No custom LLVM pass was written,** and the AVX-512 question (why 256-bit registers) was not pursued.
- **Platform:** x86-64 Linux, LLVM 18.1.3.

## Reproducing

```sh
cd docs/part32/code && ./build.sh
cd ../../part37/code
./stages.sh > stages_out.txt && ./walk.sh > walk_out.txt && ./remarks.sh > remarks_out.txt && ./ops_table.sh > ops_table_out.txt
./mca.py > mca_out.txt && ./mca.py --loops > loops_out.txt
./variants.sh > variants_out.txt && ./summarize_variants.py > variants_summary.txt
./check_llvm.py > check_llvm_out.txt && ./claims_mutation.py > claims_mutation_out.txt
cd ../../part15/code && ./run_lit.sh          # 146 tests
```

## Chapter summary

- After MLIR, `mgc` writes a `.ll` file (LLVM IR in SSA form: `phi` for loop counters, `getelementptr` for addresses, `fadd double` with no flags). `opt` then deletes the memref-descriptor packing, turns `malloc` plus a zero-fill loop into `calloc`, keeps the matrix product's running sum in a register, and unrolls the inner loop.
- The default `ijk` loop is **not vectorized** because it is a floating-point reduction and LLVM "cannot prove it is safe to reorder floating-point operations". Giving it permission (the `reassoc` flag in the IR) makes it vectorize, **and it gets no faster**: the vectorized loop gathers the strided column of `b`. The loop order, not the vectorizer's permission, is what separates the two (4.6× at N = 256, 10.9× at N = 512).
- `llvm-mca` correctly predicts that the ijk chain costs about ten times more than the ikj loop per multiply-add, and incorrectly predicts a 15× gain from vectorizing ijk: it models the core, not the memory.
- clang's `-ffast-math` does nothing to a `.ll` file (the assembly is byte for byte identical); the flags must be in the IR. The `contract` flag turns ikj's multiply and add into fused multiply-adds, +24% at N = 512 on this machine and no clear gain at N = 256.
- Element-wise operations vectorize; `exp` and `log` do not (library calls); the row reductions vectorize across rows with gathers.
- Eighteen checks pass; six wrong inputs were caught, and one of them showed that the vectorizer declines the reassociated ijk loop without AVX.

## Self-check questions

Each answer is collapsed; try the question first.

1. Why does LLVM refuse to vectorize `sum = sum + a * b` but vectorize `c[j] = c[j] + x * b[j]`?

    ??? note "Answer"
        The first is a reduction: vectorizing it computes several partial sums and adds them at the end, in a different order than the program wrote, and floating-point addition is not associative, so the result could differ in the last digits. LLVM keeps exactly the program's order unless a `reassoc` flag allows otherwise. The second updates a different element each iteration, so the iterations are independent and doing four at once changes no individual result.

2. The `fadd` in the IR has no flags. Where would a C programmer have gotten them, and why did `-ffast-math` do nothing here?

    ??? note "Answer"
        When clang compiles C or C++ source, `-ffast-math` makes the *front end* put fast-math flags (`reassoc`, `nnan`, …) on the instructions it generates. `mgc` generates its instructions through MLIR, with no flags, and then clang is handed a finished `.ll` file; clang's optimizer reads the flags that are there and does not add any. The assembly with and without the option was byte for byte identical. The flag has to be on the instruction in the IR (`fadd reassoc double`, or `fastmath<reassoc>` in MLIR).

3. With `reassoc` the ijk loop was vectorized. Why was it not faster?

    ??? note "Answer"
        The loop reads `b` down a column, one element per row, so a vector of four consecutive `k` values has to be gathered from four different rows (the assembly has 16 `vgather` instructions where ikj has none). The vectorized loop moves the same scattered data a scalar loop would. The timings (0.64 against 0.67 GFLOP/s at N = 512) say the arithmetic was not the bottleneck. This is an inference from the instruction counts and the timings; cache misses were not measured.

4. What does `llvm-mca` model, and what did the experiment show about its limits?

    ??? note "Answer"
        It models the CPU core: instruction latencies, issue ports and dispatch width, with every load assumed to hit the L1 cache. It ranked ikj above ijk correctly (0.29 against 3.02 cycles per multiply-add) but predicted that vectorizing ijk would be 15 times better (0.20), which the measurement contradicted, because the strided column walk (the real limit) is a memory-system effect it does not simulate.

5. What does the `contract` flag allow, and why does LLVM need to be told?

    ??? note "Answer"
        It allows a `fmul` followed by a `fadd` to be fused into one fused multiply-add (`vfmadd`), which rounds once instead of twice and so can give a slightly different result. Without the flag LLVM must keep two roundings. C compilers grant it by default for C source (`-ffp-contract=on`), which is why it is rarely noticed; a `.ll` file generated from MLIR has no flags. With the flag the ikj loop became `vfmadd` instructions and ran about 24% faster at N = 512 (and showed no clear gain at N = 256).

6. In `ops_table_out.txt`, `exp` has no packed arithmetic. What does the assembly do instead, and why does that matter for the transformer chapters?

    ??? note "Answer"
        It calls the C library's `exp` once per element: LLVM has no vector version of it to use. Softmax in every attention head (Chapters 29 to 36) computes `exp` over the whole score matrix (112 × 112 per head in Chapters 35 and 36), so those calls are a large part of the work that the matrix products' loop-order tuning does not touch. This chapter did not measure how large.

7. The chapter's first `opt` experiment showed 0 vector lines for every pass. What was wrong?

    ??? note "Answer"
        `opt` was run without a target (`-mtriple`, `-mcpu`), so it had no description of the machine's vector instructions and the vectorizer had nothing to vectorize with. With `-mtriple=x86_64-unknown-linux-gnu -mcpu=native` the same passes vectorize. One of the six wrong inputs in `claims_mutation.py` reproduces this on purpose, and the checker catches it.
