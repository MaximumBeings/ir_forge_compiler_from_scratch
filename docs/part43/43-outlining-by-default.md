# 43. Outlining by Default: What the Calls Cost, and Which Defaults Changed

**What you will understand:** how to decide whether an optimization should be on by default, with the cost side measured instead of assumed. Chapter 38's outlining pass moves every loop nest of a big function into a shared, deduplicated function and replaces it with a call. That cut the compile time of the training programs, but the only run-time measurements were a few single runs (0.4 s against 0.5 s at 32 steps). This chapter measures what the calls cost at run time in the one way that does not wobble, **exact instruction counts**, and in the way that does (wall time), compares compile times too, and then changes `mgc` so that loops are lowered last to first (Chapter 42) and big functions are outlined **by default**, with switches to turn each off.

**What you need to know first:** Chapters 38 (outlining) and 42 (the last-to-first lowering). No compiler pass changes in this chapter; the new `mgc` driver lives in `docs/part43/code/mgc`.

!!! tip "Compile and run"
    ```sh
    cd docs/part43/code                                  # needs Chapter 42's build: ../../part42/code/build.sh
    ./bench_runtime.py > bench_runtime_out.txt           # run time, 7 runs each (about 25 minutes: the -O2 builds without outlining are slow)
    ./count_instructions.py > count_instructions_out.txt # exact instructions under callgrind (about 15 minutes)
    ./bench_interleaved.py > bench_interleaved_out.txt   # the 200-step program, plain and outlined run alternately (about 10 minutes)
    ./check_defaults.py > check_defaults_out.txt         # the checks of this page (about 40 seconds; needs valgrind)
    ./mutation.py > mutation_out.txt                     # 7 WRONG drivers the checker must catch (about 5 minutes)
    cd ../../part15/code && ./run_lit.sh                 # the whole test suite
    ```
    Every listing and output on this page comes from these commands. Times are from one 4-core machine and are not repeatable to the second.

!!! note "Why this page shows a mutation run, and why 'caught' is the wanted result"
    `mutation.py` writes broken copies of the driver and expects the checker to fail on each. "Caught" is good; "NOT CAUGHT" would be a gap. Nothing on this page is a failing test.

## What an outlined call costs: exact instructions

`valgrind --tool=callgrind` counts every instruction an executable runs, and the count is repeatable on one setup. (It is not identical between setups: the same program counted 488,922,861 instructions when I ran it from my shell and 488,823,421 under the test suite, 0.02% apart, because the dynamic loader's work depends on the environment. That is why the checker prints rounded figures.) Each program is built twice (loops lowered last to first; with and without `--outline`) and run under it. "Calls" is the number of calls to outlined functions in the program (its `main` is straight-line, so each runs once):

```text
--8<-- "docs/part43/code/count_instructions_out.txt"
```

At `clang -O0`, the three programs execute **0.01% to 0.02% more instructions** when outlined: about 34 to 45 instructions per call (a call, the memref arguments, the return), against several hundred thousand instructions of work per loop nest. Even for the 200-step program with 86,144 calls the extra is 3.8 million instructions of 17.8 billion.

At `-O2`, Chapter 35's program runs **8.2% more**: 7.5 million instructions, about 3,900 per call. That is not a call overhead. I looked a little:

- The extra instructions are all in the program's own code (56.0 million instructions in the plain executable's eight functions against 63.5 million in the outlined one's sixteen); the library functions (`exp`, `memset`, `malloc`) execute the same counts in both.
- It is not that the outlined loops fail to vectorize: LLVM's vectorizer reports 1,390 vectorized loops for the plain file and 1,396 for the outlined one.

I did not find the cause. A candidate that I did **not** test is that clang, seeing everything in one function, optimizes across neighbouring loop nests (forwarding stored values, merging allocations) and cannot across a call. So the honest statement is: **at `-O2` outlining costs about 8% more instructions on the one program measured, for a reason not established.**

## What it costs in wall-clock time: noise

Run time in seconds, 7 runs each, pinned to one core; compile times of those executables are on the right:

```text
--8<-- "docs/part43/code/bench_runtime_out.txt"
```

The ratios of outlined to plain run time wander between 0.92 and 1.19, in both directions (the 200-step program, 1.10 at the minimum and 1.07 at the median). The 10-step programs run for 0.03 to 0.17 seconds, which is too short to resolve a 1% difference, and the 200-step one ran 10% slower outlined. So I repeated the 200-step program with the two executables run **alternately**, so that drift in the machine's speed hits both the same way:

```text
--8<-- "docs/part43/code/bench_interleaved_out.txt"
```

Now the outlined one is *faster*, by 9% at the minimum and 21% at the median. The plain executable's own nine runs range from 3.1 to 4.3 seconds, a 40% spread that is larger than any effect being looked for. Both runs are real measurements, and together they say that **on this machine wall-clock time cannot resolve a difference of under about 20% for these runs**. The instruction counts (0.02% at `-O0`) are the usable evidence, and they are consistent with "no measurable difference at `-O0`"; they say nothing about cache and memory effects, which the instruction count cannot see and which I did not measure.

## What it buys: compile time

The compile-time column of the table above (whole `mgc build`, one run, loops lowered last to first in both):

| program | clang | plain | outlined |
|---|---|---|---|
| Chapter 35, 10 steps (785 lines) | -O0 | 8 s | 4 s |
| Chapter 35, 10 steps | -O2 | 97 s | 22 s |
| Chapter 36, 10 steps (1,817 lines) | -O0 | 8 s | 6 s |
| Chapter 36, 10 steps | -O2 | **728 s** | 95 s |
| Chapter 36, 200 steps (29,552 lines) | -O0 | 149 s | 91 s |

The last-to-first lowering of Chapter 42 removed the quadratic from the MLIR stage, but it does not touch `clang`: compiling the 10-step program at `-O2` takes **12 minutes** without outlining and 95 seconds with it (7.7×), and Chapter 35's 4.4×. That is a reason for outlining to stay even after Chapter 42: it deduplicates the code that `clang` has to optimize (Chapter 35's program, for example, becomes 80 outlined functions called 1,928 times). I did not measure why `clang -O2` is so slow on the one big function.

## The decision, and what changed

On this evidence: outlining costs **a handful of instructions per call at `-O0`**, perhaps 8% more instructions at `-O2` on one program (unexplained), and an unresolved amount of wall time; it saves **minutes** of compile time at `-O2` and cuts it by a quarter to a half at `-O0` for the big programs. The last-to-first lowering costs nothing visible (identical output, Chapter 42). So both become defaults. The new driver:

```sh
--8<-- "docs/part43/code/mgc"
```

- `mgc` lowers loops last to first and outlines unless told otherwise: **`--no-reverse-loops`** and **`--no-outline`** turn each off. The old spellings `--outline` and `--reverse-loops` still work and mean what they say.
- Outlining touches only functions with **32 or more top-level loop nests** (the pass's `min-loops` default), so every small program compiles to exactly what it did before. The checker builds the self-attention example and finds no outlined function in it.
- **Older chapters keep their own drivers**, as always in this book: each chapter's tests run that chapter's own `mgc`, so nothing recorded earlier changes. The new default is only in `part43/code/mgc`, which uses Chapter 42's `mg-opt`.

## Tests

One new `lit` file `test/defaults43/check.mlir` (the suite is now 155 tests). The checker:

1. **Which passes:** a stand-in for `mg-opt` records its arguments; the default asks for `--mg-outline-loops` and `--mg-scf-to-cf-reverse` and not `--convert-scf-to-cf`; each `--no-...` switch removes exactly what it names; the old spellings equal the default.
2. **Same output:** on every third book example (36 programs, each under 400 lines and accepted by the front end), `mgc run` with the defaults prints what `--no-outline --no-reverse-loops` prints.
3. **Small programs untouched:** the self-attention example has no outlined function.
4. **Big programs outlined:** Chapter 35's 10-step program has 80 outlined functions by default, none with `--no-outline`, and the same output.
5. **Run-time cost, in instructions:** under 0.1% more at `-O0`, 20 to 60 instructions per call.

```text
--8<-- "docs/part43/code/check_defaults_out.txt"
```

### Are the checks good enough? Seven wrong drivers.

```text
--8<-- "docs/part43/code/mutation_out.txt"
```

All seven are caught. The two switches that are "accepted but do nothing" and the default that is flipped back are caught by the plumbing check, **not** by any output comparison; that is expected, because lowering last to first and outlining do not change what a program prints (Chapters 38 and 42). A driver that quietly lost the speed-up would print the same answers, so the check of which passes are requested is the only thing that can notice, and an executable-level check would need a timing, which Chapter 38's tests avoid.

## Limits and what is not established

- **The 8% at `-O2` is unexplained,** and was measured by instructions on **one** program; `-O3` was not measured at all, and the `-O2` instruction count was not measured for the 200-step program (its `-O2` build was not attempted).
- **Wall-clock run time was not resolved.** The two measurements disagree in sign and the machine's own spread exceeds the effect. Memory and cache behaviour, which instruction counts do not capture, are untested.
- **Compile times are single runs** on one machine; the 728-second figure is one build.
- **The default changes for big functions only.** Whoever wants the old IR (for reading it, as Chapter 37 does) must pass `--no-outline`; the book's earlier chapters are not affected because they use their own frozen drivers.
- **The 36 examples of the check are every third example,** not all: the examples of 400 lines or more and the ones the front end rejects are excluded.
- **Debuggability was not studied:** outlined functions have generated names (`mg_outlined_N`), and a backtrace would show them.

## Reproducing

```sh
cd docs/part43/code
./bench_runtime.py > bench_runtime_out.txt && ./count_instructions.py > count_instructions_out.txt && ./bench_interleaved.py > bench_interleaved_out.txt
./check_defaults.py > check_defaults_out.txt && ./mutation.py > mutation_out.txt
cd ../../part15/code && ./run_lit.sh          # 155 tests
```

## Chapter summary

- Outlining's run-time cost at `-O0` is **34 to 45 instructions per call**, 0.01% to 0.02% of the program's instructions, measured exactly on three programs including the 200-step one (86,144 calls).
- At `-O2` it was **8.2% more instructions** on Chapter 35's program, for a reason not established (not vectorization: 1,390 against 1,396 vectorized loops).
- Wall-clock time could not resolve the difference: ratios between 0.79 and 1.19 in different runs.
- Outlining cut `clang -O2` compile time from 728 to 95 seconds (Chapter 36's 10 steps) and from 97 to 22 seconds (Chapter 35's), and `-O0` compile time of the 200-step program from 149 to 91 seconds.
- `mgc` now lowers loops last to first and outlines big functions by default; `--no-outline` and `--no-reverse-loops` turn them off; small programs are unchanged; seven wrong drivers are caught.

## Self-check questions

Each answer is collapsed; try the question first.

1. Why does the chapter rely on instruction counts and not on wall-clock time for the cost of the calls?

    ??? note "Answer"
        Instruction counts under callgrind are exact and repeatable; wall-clock time here varied by 40% between runs of the same executable (3.1 to 4.3 seconds), more than any effect being measured, and two measurements of the same comparison disagreed in sign (1.10 and 0.91).

2. What does 34 extra instructions per call mean for a loop nest that does hundreds of thousands of instructions of work?

    ??? note "Answer"
        Nothing measurable: 34 instructions are the call itself, passing the memref descriptors as arguments, and the return, against a body that runs hundreds of thousands. Over 1,928 calls it is 66,050 extra instructions in a program of 489 million (0.0135%).

3. The `-O2` build executes 8.2% more instructions when outlined. What was ruled out and what was not tested?

    ??? note "Answer"
        Ruled out as the explanation: a loss of vectorization (1,390 against 1,396 vectorized loops) and the library calls (identical counts). Not tested: that clang optimizes across neighbouring loop nests in one big function (forwarding stores, merging allocations) and cannot across a call. The cause is not established.

4. Why did the new defaults not require changing any earlier chapter's tests?

    ??? note "Answer"
        Each chapter's tests run that chapter's own copy of the `mgc` driver, and Chapter 43's new defaults are only in `part43/code/mgc`. The older drivers still behave as they did, so everything recorded earlier reproduces.

5. Why is "the default lowering order is flipped back" caught only by the check of which passes are asked for?

    ??? note "Answer"
        Because the lowering order does not change the printed output (Chapter 42 showed byte-identical IR), so no output comparison can see it. Only a check on the arguments passed to `mg-opt`, or a measurement of cost, can notice the speed-up has gone.

6. Name three limits of the claims of this chapter.

    ??? note "Answer"
        Any of: the 8% at `-O2` is unexplained and measured on one program; `-O3` and the 200-step program at `-O2` were not measured; wall-clock time was not resolved; compile times are single runs on one machine; the default check covers every third example, not all; debuggability of the generated function names was not studied.
