# 38. Why Compile Time Was Quadratic, and a Pass That Outlines Loop Nests

**What you will understand:** why Chapter 36's training program took about 40 minutes to compile, found by measuring one stage at a time; how to isolate a cost like that with a synthetic experiment; and the compiler change that fixes it, **`--mg-outline-loops`**: a new MLIR pass, written for this book, that cuts a huge function into small shared ones. With it (`mgc --outline`) the same 29,552-line program compiles in **94 seconds** and prints exactly the numbers Chapter 36 recorded. This is the book's first compiler change since Chapter 32, and the first one whose reason is compile time.

**What you need to know first:** Chapter 36 (the training program whose compile time is the problem), Chapter 5 (the lowering from `affine` to `scf` to the LLVM dialect, where the time goes) and Chapter 37 (what the final stages look like). The pass is MLIR C++ (a `Pass`, a `func::FuncOp`, building and cloning operations); the page explains each step, but reading it is easier if you have seen Chapter 2's and Chapter 19's passes.

!!! tip "Compile and run"
    ```sh
    cd docs/part38/code && ./build.sh                 # builds mg-opt with the new pass (about a minute); this is now the newest compiler
    python3 make_examples.py                          # (re)writes the four example programs
    ./run_examples.sh > examples_out.txt              # each example without and with --outline
    ./show_ir.sh > show_ir_out.txt                    # the IR before and after, for one example
    ./pass_timing.py > pass_timing_out.txt            # which pass is slow? (about 3 minutes)
    ./synthetic.py > synthetic_out.txt                # the cost isolated on synthetic loops (about 3 minutes)
    ./scaling.py > scaling_out.txt                    # every stage's time, with and without outlining, 1 to 32 steps (about 4 minutes)
    ./full200.sh > full200_out.txt                    # the full 200-step program with --outline, compared with Chapter 36's recorded output (under 2 minutes)
    ./mutation.sh > mutation_out.txt                  # 11 broken versions of the driver and the pass, each re-tested (about 12 minutes)
    cd ../../part15/code && ./run_lit.sh              # the whole test suite (now run with this chapter's mg-opt)
    ```
    Every listing and output on this page comes from these commands. `mgc` in this directory is Chapter 32's with one new option, `--outline`.

!!! note "Why this page shows a mutation run, and why 'caught' is the wanted result"
    The mutation output breaks the pass on purpose, one way at a time, and expects the tests to fail. "Caught" is good; "NOT CAUGHT" would be a gap (there is none this time). Nothing on this page is a failing test.

## The problem: 40 minutes

Chapter 36's 200-step training program compiled and ran in 39 minutes 35 seconds (`check_lm2.py --full`), and nearly all of that was compile time (the program itself runs for seconds). Chapter 36 said "why the cost grows faster than the size was not investigated". Here is the investigation. `mgc` is a chain of stages (Chapter 37), so time each one. The training program cut to *k* steps has *k* times the loop nests in `main`, and this is `scaling.py`'s output for the **plain** rows (the "outlined" rows are this chapter's fix, discussed below):

```text
--8<-- "docs/part38/code/scaling_out.txt"
```

Look at the plain rows. Every stage grows with the program, but the **`lower`** stage (the second `mg-opt` run: `--lower-affine --convert-scf-to-cf` and the conversions to the LLVM dialect) grows *faster* than the program: 7.6 → 17.3 → 49.3 seconds when the number of steps goes 8 → 16 → 32, while the front end, `translate` and `clang` each roughly double. At 32 steps `lower` is 82% of the compile time.

## Which pass? The compiler's own timing report

`mg-opt --mlir-timing` prints where a pipeline spent its time, per pass. For the 16-step program (`pass_timing.py`):

```text
--8<-- "docs/part38/code/pass_timing_out.txt"
```

One pass, **`SCFToControlFlow`** (it turns structured `scf.for` loops into basic blocks with branches), takes 64% of the lowering at 16 steps. The table underneath times it alone against the number of loop nests: each doubling of the steps multiplies the loop count by 1.34 to 1.89 (it approaches 2 as the constant part of the program, the weights and mask literals, becomes small) and the time by **about 3** (1.83, 3.27, 2.89, 3.04, 3.19). A cost that triples while the loop count grows by a factor of 1.8 to 1.9 grows like the loop count to the power of about 1.8: **close to quadratic** in the measured range. (Extrapolating to 200 steps would be a guess: this pass alone would take on the order of a quarter of an hour.)

## Isolating the cause: loops per *function*

The unrolled training program puts every loop nest into **one function**, `main` (the `def`s are separate functions, but the training steps are `let`s in `main`). Is the cost about the number of loops in one function, or about the number of loops in the whole module? A synthetic experiment tells them apart: *n* tiny nests (each copies four numbers) written directly as MLIR, either all in one function or in functions of 500 nests each (`synthetic.py`):

```text
--8<-- "docs/part38/code/synthetic_out.txt"
```

- **All in one function: super-linear, steeply.** 2,000 nests: 0.06 s; 8,000: 5.2 s; 32,000: **88 s**. Doubling *n* multiplies the time by 9.0 and 9.7 at first and by 4.8 and 3.6 later, so it is not a clean power law (the later factors are smaller; why is not known).
- **The same loops in functions of 500: linear.** 32,000 nests: **0.42 s**, 200 times faster, and each doubling roughly doubles the time (0.02, 0.04, 0.08, 0.23, 0.42).
- So the cost is a property of **how many loops one function holds**, not of how many the module holds. **The mechanism inside MLIR was not identified.** A natural guess is that lowering each loop splits the function's block and moves everything after it, which makes the total work grow with the square of the length; that would explain the shape but it was **not tested** (no profiler was run and the MLIR source was not read).

That suggests the fix: **do not put thousands of loops in one function.**

## The fix: outline each nest into a shared function

`--mg-outline-loops` (new, `OutlineLoops.cpp`) walks every function that has at least 32 top-level `affine.for` nests (the threshold is an option, `min-loops`). For each nest it:

1. finds the values the nest uses that are defined **outside** it;
2. **clones** the `arith.constant`s into the new function and turns **everything else** into an argument (a memref, or an index or float computed outside: the run-time sizes of a dynamic-shape program, for example);
3. builds `func.func private @mg_outlined_N(args) { the nest; return }`, prints it, and **if an identical function (same text, ignoring the name) already exists, uses that one and throws the new one away**;
4. replaces the nest with a `func.call`.

Step 3 is what makes it more than a trick to dodge a quadratic: a program with 190,000 loop nests (the 200-step program, by extrapolation) has **75 distinct ones**, so the output has 75 small functions and `main` is a list of calls. The whole pass:

```cpp
--8<-- "docs/part38/code/OutlineLoops.cpp"
```

The three details worth reading: the **copy constructor** (MLIR's pass framework copies passes, and an `Option` member is not copyable, so the pass has to say how: the first build of this chapter failed to compile on exactly that), the `definedOutside` test (an operand is outside if the operation that defines it, or the operation owning the block it is an argument of, is not inside the nest), and the **key**: the function printed as text. Two nests are "the same" when they print the same, which is exactly when they are the same loops over memrefs of the same types, with the same arithmetic and the same constants. `a + a` (one input used twice) and `a + b` (two) print differently and so stay different functions, which Example 1 shows.

## What it does to the IR

`show_ir.sh` keeps the affine IR of `examples/02_one_nest_forty_times.mg` (forty additions of 2 × 2 matrices) with and without the pass:

```text
--8<-- "docs/part38/code/show_ir_out.txt"
```

Before, `main` contains the nest, in place, forty times. After, there is one function and forty calls with different memrefs (the first three and the last are shown). The function is a copy of the nest with its three memrefs as arguments, and nothing else about the loop has changed.

## Examples

Four small programs, each run without and with `--outline` (the printed memory address is replaced by `0x…`, since it changes from run to run). The last line of each block counts the `affine.for` in the kept IR:

```text
--8<-- "docs/part38/code/examples_out.txt"
```

1. **`01_four_distinct_nests.mg`:** 35 nests (twelve rounds of an add on 2 × 2, a product on 3 × 3 and a transpose on 3 × 3; the very first add, `a + a`, adds a constant to itself and the compiler folds it into a constant, so the 36th nest does not exist) become 35 calls of **four** functions, not three: `b * b` (a matrix times *itself*) takes one input, every later product takes two, so they print differently. Plain: 70 `affine.for` (35 nests of two loops); outlined: 8 (four functions of one nest each).
2. **`02_one_nest_forty_times.mg`:** 39 nests, **one** function.
3. **`03_dynamic_shapes.mg`:** a function over matrices of any size, with 39 nests in its body. The nests use the run-time sizes; the outlined functions take them as **arguments** (`%arg3: index, %arg4: index`), and there are two (the first nest adds `a` to itself; the other 38 add two different matrices). The answer is the same.
4. **`04_below_threshold.mg`:** two nests, below the threshold of 32: nothing is outlined.

## Result

The "outlined" rows of the scaling table above, side by side with the plain ones:

| steps | plain: compile total (s) | outlined: compile total (s) | plain `lower` | outlined `lower` |
|---|---|---|---|---|
| 1 | 3.8 | 3.3 | 2.0 | 1.2 |
| 4 | 6.1 | 3.9 | 3.7 | 1.3 |
| 8 | 11.1 | 4.9 | 7.6 | 1.6 |
| 16 | 23.1 | 7.1 | 17.3 | 2.0 |
| 32 | 59.9 | 13.6 | 49.3 | 3.2 |

At 32 steps the compile time falls from 59.9 s to 13.6 s, and the `lower` stage from 49.3 s to 3.2 s. Every row prints exactly the same output with and without the pass (`scaling.py` compares the 458 words of each pair: all `True`). The number of distinct functions is 75 whatever the number of steps. What is left grows roughly linearly: `clang` (6.1 s at 32 steps) and `translate` (2.9 s) now dominate.

And the program of Chapter 36, at its full 200 steps (`full200.sh`):

```text
--8<-- "docs/part38/code/full200_out.txt"
```

**94 seconds to compile and 4 to run, against about 40 minutes**, and the output is **identical** to Chapter 36's recorded output, line for line: all eight checkpoints, the held-out result, the chunk counts and the four attention patterns. (This is the strongest check in the chapter, since that run was itself checked digit for digit against the Python reference in Chapter 36.) The 40-minute figure is Chapter 36's, measured with other jobs sharing the machine for part of it; the 94 seconds is one run.

Does calling a function per nest cost run time? Not visibly here: the 32-step program runs in 0.4 s plain and 0.5 s outlined (one run each, not a benchmark), and the full program's 4 seconds includes everything. The calls pass memref descriptors, which are cheap beside a loop of 112 × 112 element operations. This was not measured carefully.

## Tests

Three new `lit` files in `test/outline38/` (the suite is now 149 tests):

| Test | What it checks |
|---|---|
| `pass` | the pass on hand-written IR: two identical nests become one function called twice (with the constant cloned in, not passed), a nest of a different shape becomes another function, a scalar defined outside becomes an argument, a nested 2-deep nest is outlined whole, call order is kept, and with the **default** threshold none of these small functions is touched |
| `structure` | the IR `mgc --outline` keeps, for the four examples: the exact number of outlined functions, calls and remaining loops (35 calls of 4 functions with 8 loops left; 39 calls of 1 function; 39 calls of 2 dynamic-shape functions whose signature is checked; nothing for the program below the threshold) |
| `results` | each example run with and without `--outline` gives byte-identical output (address removed), and the values themselves are pinned |

**The test suite now runs with this chapter's `mg-opt`** (`run_lit.sh` prefers the newest build, which is now Chapter 38's; it is Chapter 32's plus the pass), so all 146 earlier tests also pass on the new compiler: 149 pass. The continuous-integration script and workflow now build `docs/part38/code`, and the build cache is keyed on this chapter's sources as well as Chapter 32's. **A lesson from the first CI run of this chapter:** the Chapter 37 `claims` test failed there, because its scripts called `mgc` with its default compiler, Chapter 32's build, which CI no longer builds (it builds only the newest). The test now passes the compiler under test (`env MG_OPT=%mg-opt`, as the Chapter 35 and 36 tests do) and Chapter 37's scripts pick the newest build that exists. It was reproduced locally by hiding Chapter 32's build directory and running the whole suite: 149 passed.

### Are the tests good enough? Break the pass eleven ways.

`mutation.sh` breaks the driver twice and the pass nine times (each pass mutation is a full rebuild of `mg-opt`, about a minute) and re-runs the three tests:

```text
--8<-- "docs/part38/code/mutation_out.txt"
```

All eleven are caught. Two lines are worth reading:

- **"The original loop nest is not erased"** would make every nest run twice. For these programs that is *harmless* (a copy of an elementwise result is idempotent), so the `results` test **cannot** see it: the output is unchanged. It is caught by `structure` (which counts the loops left in `main`) and by `pass` (which checks the IR). This is why the chapter has IR-level tests and not only output comparisons.
- **"The threshold is off by one"** is caught **only** by `pass`, which has a function with exactly one nest and runs with `min-loops=1`. The example programs have 35 and 39 nests against a threshold of 32, so nothing in them sits at the boundary.

## Limits and what is not established

- **The mechanism is not identified.** The measurements show the cost of `SCFToControlFlow` depends on the number of loops in one function and not in the module, and that splitting the function removes it. Why (block splitting, an analysis that is recomputed, memory behaviour) was not found. The doubling factors were not a clean power law (9.0, 9.7, 4.8, 3.6 in the synthetic experiment), and the extrapolation to 200 steps is not a prediction.
- **Only top-level `affine.for` nests are outlined,** in functions with at least 32 of them. The straight-line `affine.store`s that initialize the 112 × 112 mask and the other literals in `main` (21,714 of them directly in `main` in the 1-step program) are untouched; whether they cost anything was not measured. The threshold of 32 was chosen by hand and not tuned.
- **Deduplication is by printed text,** so it finds nests that are identical, not nests that are equivalent: `a + a` and `a + b` stay different (Example 1), a nest with its two loops in the other order is another function.
- **The pass is off by default** (`--outline` or `--mg-outline-loops`). Making it the default would change the IR of every program with 32 or more top-level nests (the earlier chapters' tests would need new expectations), and was not done.
- **Interaction with other options is only partly tested.** `--outline` runs after `--passes`, so tiling or unrolling inside a nest happens first; the combination was not tested. The GPU path (`mgc ptx`) is unchanged and the pass is not run there.
- **Run time was not benchmarked.** The calls cost something; the measurements above (0.4 s against 0.5 s at 32 steps, 4 s for 200 steps) are single runs.
- **One machine, one run each** for every timing here; Chapter 36's 40 minutes were measured with other jobs running on the same machine.
- **Compile time is still linear in the program,** and `clang` at `-O0` and `mlir-translate` are what is left; no attempt was made to reduce them.
- **Platform:** x86-64 Linux, LLVM/MLIR 18.1.3.

## Reproducing

```sh
cd docs/part38/code && ./build.sh
python3 make_examples.py && ./run_examples.sh > examples_out.txt && ./show_ir.sh > show_ir_out.txt
./pass_timing.py > pass_timing_out.txt && ./synthetic.py > synthetic_out.txt && ./scaling.py > scaling_out.txt
./full200.sh > full200_out.txt && ./mutation.sh > mutation_out.txt
cd ../../part15/code && ./run_lit.sh          # 149 tests
```

## Chapter summary

- Chapter 36's 40-minute compile was one MLIR pass, `SCFToControlFlow`, whose time grows much faster than the number of loops in **one function** (about 3× for every doubling of the steps; 88 s for 32,000 synthetic loops in one function against 0.4 s for the same loops in functions of 500).
- **`--mg-outline-loops`** moves each top-level loop nest into a small private function, clones constants in, passes everything else as arguments, and **deduplicates** identical functions: the 200-step program has 75 distinct nests. `mgc --outline` turns it on.
- With it the 200-step training program compiles in **94 s and runs in 4 s**, and prints exactly what Chapter 36 recorded; at 32 steps the compile falls from 59.9 s to 13.6 s.
- The mechanism inside MLIR was not found; the evidence is a synthetic experiment that isolates the number of loops per function.
- Eleven deliberate breakages of the driver and the pass were all caught; one (not erasing the original loop) is invisible to an output comparison and is caught only by IR-level tests.
- The test suite and the CI now use this chapter's `mg-opt`; the pass is opt-in.

## Self-check questions

Each answer is collapsed; try the question first.

1. How did the chapter find which stage and which pass made the compile slow?

    ??? note "Answer"
        It timed each `mgc` stage separately at several program sizes (the `lower` stage grew faster than the rest), then used `mg-opt --mlir-timing`, which reports time per pass (one pass, `SCFToControlFlow`, took 64% of the lowering), then timed that pass alone against the number of loops.

2. What does the synthetic experiment show, and what does it not show?

    ??? note "Answer"
        It shows the cost depends on how many loops one function holds: the same 32,000 loop nests take 88 s in one function and 0.4 s in functions of 500. It does not show why: the cause inside MLIR (for instance repeated block splitting) was not identified, and the growth was not a clean power law.

3. Why does the pass clone `arith.constant` operations into the outlined function instead of passing them as arguments?

    ??? note "Answer"
        So that two nests that differ only in where their constants were defined still print the same and are deduplicated into one function. A constant passed as an argument would also work, but every nest would then have its own argument list and the calls would carry values that never change. Cloning also keeps constants such as `2.0` visible inside the loop body, where later passes can fold them.

4. `a + a` and `a + b` on the same shapes become two different outlined functions. Why, and is that a bug?

    ??? note "Answer"
        The key is the printed function. `a + a` uses one input twice, so its function has one input plus the output; `a + b` has two inputs. They print differently, so they are different functions. It is not incorrect (each computes the right thing); it only means two functions where one might do. Matching by structure rather than by text would merge them, at the cost of a more complicated pass.

5. One mutation, "the original loop nest is not erased", passed the output comparison. Why, and what caught it?

    ??? note "Answer"
        Leaving the original nest in `main` runs each computation twice, writing the same values to the same memref, so the printed result is unchanged for these elementwise programs. The structural test counts the `affine.for` left after outlining (8 for Example 1, not 78), and the pass test checks the IR, so both see the leftover loops. An output comparison alone could not.

6. Why is the pass off by default?

    ??? note "Answer"
        Turning it on would change the IR of every program with at least 32 top-level loop nests, and the earlier chapters' tests and recorded outputs were written against the old IR. Its benefit appears only for very large programs such as the unrolled training steps, so `--outline` is an opt-in; a default would be a separate, deliberate change.

7. The timings here come from single runs. How does that limit what the chapter can say?

    ??? note "Answer"
        Differences of a few percent (such as the 0.4 s against 0.5 s run time at 32 steps) are not evidence of anything. The large effects (88 s against 0.4 s; 60 s against 14 s; about 40 minutes against 94 s) are far outside run-to-run noise, so the conclusions drawn from them stand; the claim that outlining costs "nothing visible" at run time rests on a single small measurement and is only suggestive.
