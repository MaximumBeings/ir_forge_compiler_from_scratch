# 42. Lowering the Loops Last to First: Testing the Idea Chapter 39 Left Open

<p style="text-align:center"><img src="../assets/goats/ch-42.svg" alt="Mountain goats on the mountain in autumn" style="max-width:100%;height:auto;border-radius:6px"></p>

**What you will understand:** how a hypothesis that comes out of a profile gets tested. Chapter 39 found *why* MLIR's `SCFToControlFlow` is quadratic in the number of loops in one function (each loop splits its block and moves everything behind it) and said, in its limits section, that lowering the loops from the last to the first "would make each split move a short tail; that is an idea suggested by the mechanism, not something tested here". This chapter tests it. It writes a small pass, `--mg-scf-to-cf-reverse`, that lowers the top-level statements of a function one at a time, last first, and measures it: against MLIR's own pass on a synthetic function (312 seconds against 1.2 seconds at 64,000 loops), on the real 200-step training program (the lowering pass goes from 2,106 seconds to 3 seconds with no outlining at all), and on its output, which turns out to be byte-for-byte the same IR. It also measures what the pass does **not** fix.

**What you need to know first:** Chapter 38 (the quadratic, outlining) and Chapter 39 (the profile and the mechanism: `Block::splitBlock`, `transferNodesFromList`). The new pass is about 40 lines of C++ on top of MLIR's own conversion patterns; you do not need to know C++ to follow the measurements.

!!! tip "Compile and run"
    ```sh
    cd docs/part42/code
    ./build.sh                                   # mg-opt of this chapter: Chapter 38's plus --mg-scf-to-cf-reverse (a few minutes; needs mlir-18-tools, libmlir-18-dev, cmake)
    ./scaling.py > scaling_out.txt               # synthetic loops, three lowerings, 2,000 to 64,000 loops (about 7 minutes)
    ./nested_limit.py > nested_limit_out.txt     # what the pass does not fix (about 1 minute)
    ./check_reverse.py > check_reverse_out.txt   # the checks of this page (about a minute; needs valgrind)
    ./mutation.py > mutation_out.txt             # 6 WRONG passes plus one wrong setting that the checker must catch (about 10 minutes: each rebuilds mg-opt)
    ./full200.sh > full200_out.txt               # the 200-step training program, stage by stage (about 4 minutes)
    ./pass_times_200.sh > pass_times_200_out.txt # every pass of the lowering stage on that program; the ordinary pass takes about 35 minutes: run it in the background
    cd ../../part15/code && ./run_lit.sh         # the whole test suite
    ```
    Every listing and output on this page comes from these commands. `mgc` now takes `--reverse-loops` (it substitutes the new pass for `--convert-scf-to-cf`); nothing else about it changes, and the option is **off by default** (Chapter 43 returns to what the defaults should be).

!!! note "Why this page shows a mutation run, and why 'caught' is the wanted result"
    `mutation.py` writes broken versions of the pass and expects the checker to fail on each. "Caught" is good; "NOT CAUGHT" would be a gap. Nothing on this page is a failing test.

## The idea, and why it should work

Chapter 39's profile says: lowering the loop at position *i* of a block splits the block there and **moves every operation behind it** into a new block, and the loops are lowered first to last, so loop *i* still has *n − i* unlowered nests behind it. About *n*²/2 nests are moved in all.

Now lower them in the other order. The last loop is split first: nothing is behind it. The next-to-last loop is split second, and what is behind it is the **already lowered** last loop, which is no longer a pile of operations in this block: the split left a branch behind and the loop's blocks live elsewhere. So every split moves only the operations between two neighbouring loops, a constant number, and the total is linear.

MLIR's pass cannot be told to do this (the conversion driver visits operations in program order), so the new pass drives MLIR's own lowering patterns itself:

```cpp
--8<-- "docs/part42/code/ScfToCfReverse.cpp"
```

It takes the statements of the entry block that are structured control flow (`scf.for`, `scf.if`, `scf.while`, `scf.execute_region`, `scf.index_switch`), then, from the last to the first, runs MLIR's own `populateSCFToControlFlowConversionPatterns` on **that one statement** (`applyPartialConversion` accepts a list of operations to convert; the statement's nested operations are converted with it). The patterns are MLIR's, so the lowering of each loop is by construction the one MLIR would have made; only the **order** differs. That is a claim, and the checks below test it.

`mg-opt` did not register the `scf` dialect (nothing ever parsed `scf` text, since the loops arrive as `affine.for` and `--lower-affine` creates the `scf` ones). This chapter adds it to `mg-opt.cpp`, so that the edge-case program below can be written directly in `scf`; no other behaviour changes.

## Does it fix the quadratic?

The synthetic function of Chapter 38 (`n` tiny loops, each copying four numbers, all in one function), lowered by MLIR's pass, by the new one, and, as the control that was always fast, with the loops spread over functions of 500. Times are the pass's own, from `--mlir-timing`; one run each:

```text
--8<-- "docs/part42/code/scaling_out.txt"
```

At 64,000 loops, MLIR's pass takes **311.7 seconds**; lowering last to first takes **1.2 seconds**, 260 times less, and is within 1.5× of the spread-over-functions control (0.8 seconds). The standard pass grows by about 4× per doubling at the top of the table (4.0× at the last row: quadratic), the new pass by 2.4× to 2.6×.

That 2.4× to 2.6× is a little more than the 2× of a linear algorithm, and the control column, which is linear by construction (the same functions of 500, only more of them), grows by 2.5× to 2.6× over the same last rows too. I did not find out why: memory effects at these sizes are a candidate that I did not test. What the data support is that the new pass behaves like the control, not that it is exactly linear.

### The count of instructions

Timings are noisy; instruction counts under `valgrind --tool=callgrind` are exact. The checker (below) counts the instructions spent in `ilist_traits<Operation>::transferNodesFromList`, the function Chapter 39 identified:

```text
  ok   convert-scf-to-cf: transferNodesFromList grows x3.97 and x3.98 per doubling (4 = quadratic)
  ok   last to first: transferNodesFromList grows x2.00 and x2.00 per doubling (2 = linear)
  ok   last to first: block splitting is 0.0% of the instructions at 2000 loops (convert-scf-to-cf: 5%)
```

(Lines copied from the checker's output further down.) The mechanism is the one Chapter 39 named, and it is gone: ×2.00 per doubling is exactly linear.

### What it costs when the quadratic is not there

At 2,000 loops the quadratic part is only 5% of the instructions, and the new pass runs one conversion per statement, which has a fixed price: 706 million instructions in all against 697 million for MLIR's pass, about 1% more. So by **instructions** the new pass is slightly more expensive for small functions (the checker allows up to 5% more). By **time** it is already ahead at 2,000 loops (0.018 seconds against 0.067 in the table above), because the instructions of the quadratic part are the expensive kind (Chapter 39: pointer-chasing that misses the cache). Both numbers are tiny at that size; the gap becomes large from 4,000 loops up.

## The real program

Chapter 36's 200-step training program has 190,636 loop nests in one function (`main`). Chapter 38 got its compile time from about 40 minutes to 94 seconds by outlining the nests into 75 shared functions. Here is the same program **without outlining**, lowered last to first, with the time of each stage (`full200.sh`; the program is the 200-step one compiled from source):

```text
--8<-- "docs/part42/code/full200_out.txt"
```

Without outlining, the whole compile takes **129 seconds**, and **the output is identical** to the output Chapter 36 recorded when it compiled the same program with the ordinary lowering and no outlining (the checker's md5 of the 76 lines, with the addresses and blank lines removed, is the same: `cab50027c661`). With both the new pass and outlining it takes 82 seconds.

Where did the time go? MLIR's own `--mlir-timing` report for the lowering stage, for the new pass and for the ordinary pass (`pass_times_200.sh`):

```text
--8<-- "docs/part42/code/pass_times_200_out.txt"
```

- Ordinary `SCFToControlFlow`: **2,106 seconds** of the stage's 2,173 (97%). The new pass: **3.1 seconds** of 62.8. **Everything else in the stage is the same in both**: a list of passes taking 3 to 11 seconds each, none of which dominates.
- The stage at 62 seconds is then 48% of the compile; the rest is `mlir-translate` (38 s) and `clang -O0` (23 s), also linear in the size of the program. The quadratic really was in one pass.
- The 2,106-second figure is **one run**, made while other work (builds and checks) was running on the same four-core machine; treat it as "about 35 minutes", which is consistent with Chapter 36's "about 40 minutes" for compile and run together, and not as a measurement to the second.

One more observation, not explained: with outlining added, `clang -O0` took 48 seconds, against 23 without. So outlining shortens the MLIR stages but lengthens the last one on this machine (at `-O0`). The total is still better (82 s against 129 s). I did not look into why clang is slower on the outlined file.

## Is it the same program?

The new pass only helps if it changes nothing else. The checker tests this four ways.

**1. The book's examples.** On every Mountain Goat example of the book that the front end accepts and that has under 400 lines, `--lower-affine` followed by each lowering gives output that is **byte-for-byte identical**: 107 programs, none differ (13 are skipped: 400 lines or more, or deliberately rejected by the front end).

**2. Control flow that the examples do not have.** The front end only ever produces plain loops, so the examples never contain an `scf.if` or an `scf.while`, a loop with a result or a loop inside a loop with `iter_args`. `examples/edge_cases.mlir` is hand-written `scf` with all of them, each later statement using the results of earlier ones:

```text
--8<-- "docs/part42/code/examples/edge_cases.mlir"
```

Both lowerings give the same text for it, and the lowered program, run, prints **10, 1000, 128, 153, 10153**, the values worked out in the comments by hand.

**3. Real programs run the same.** An attention example, the tiny transformer and the bigram training run print identical output with and without `--reverse-loops`.

**4. A big function.** One function of 3,000 loops lowers to byte-identical IR (1.6 megabytes) from both.

## Tests

One new `lit` file `test/reverse42/check.mlir` (the suite is now 154 tests). The full output of `check_reverse.py`:

```python
--8<-- "docs/part42/code/check_reverse.py"
```

(The listing is the checker itself.) Its output:

```text
--8<-- "docs/part42/code/check_reverse_out.txt"
```

CI now builds this chapter's `mg-opt` (the newest build, which contains everything before it); `run_lit.sh`, `ci.sh`, the workflow and its checker, and Chapter 37's scripts that look for the newest build were updated to find it.

### Are the checks good enough? Seven wrong passes.

```text
--8<-- "docs/part42/code/mutation_out.txt"
```

All seven are caught. Look at *which check* catches each:

- The two that make the order wrong (first to last, or the whole function in one call) are caught **only by the instruction count**: the output is still the right program, so no output comparison could notice them. A pass that gave the right answer but quietly lost the speed-up would be invisible without that check.
- A pass that skips top-level `scf.if` or `scf.while` is caught **only by the hand-written file**, because the book's examples contain neither. If I had trusted the 107 programs alone, this would have gone unnoticed.
- Lowering only the first 2,500 statements is caught **only by the 3,000-loop comparison** (the instruction counts stop at 2,000 loops and look at no output of a big function, so I expected this mutant to slip through and added the 3,000-loop comparison before the run; I did not run the mutants without it).

## What the pass does not fix

```text
--8<-- "docs/part42/code/nested_limit_out.txt"
```

The pass reorders only the **top-level statements of a function**. One outer loop whose body holds *n* inner loops is lowered as one statement, and inside it MLIR's driver still goes in program order, so the quadratic is back: 23.9 seconds against 24.4 seconds at 16,000 inner loops, no better at all (the small differences at 2,000 to 8,000 are noise from one run each). The training programs do not look like this (each matrix operation is its own top-level nest), which is why the pass works on them, but a program that put all its operations inside one big loop body would not benefit. Lowering the nested loops last to first too is not a matter of recursing: a lowered inner loop leaves its parent's body with several blocks, and an `scf.for` must have a single-block body, so the order of conversion has to change more than this pass does. I did not do that.

## Limits and what is not established

- **One machine, one run per cell** in the timing tables (the instruction counts are exact; the times are not). The 2,106-second figure was measured with other work running.
- **The new pass is not in MLIR.** It drives MLIR's patterns from outside and handles only the entry block's top-level statements. A real fix would go in the conversion driver or in `SCFToControlFlow` itself, and I have not read that code to see whether such a change would be accepted or would break something else.
- **Byte-identical output was shown on 107 programs, one synthetic function and one hand-written one,** not for every possible `scf` program. For any case where MLIR's patterns depend on the order of conversion the outputs could differ; none was found.
- **The nested case is not fixed** (above), and functions that are not `func.func` (a `gpu.module`, for example) are not looked at by this pass.
- **Still unexplained:** why the new pass and the control both grow by about 2.5× per doubling at the top of the table, and why `clang -O0` is slower on outlined input.
- **The default is unchanged.** Whether `mgc` should lower last to first by default, and whether outlining should be on by default, is the next chapter's question.

## Reproducing

```sh
cd docs/part42/code && ./build.sh
./scaling.py > scaling_out.txt && ./nested_limit.py > nested_limit_out.txt
./check_reverse.py > check_reverse_out.txt && ./mutation.py > mutation_out.txt
./full200.sh > full200_out.txt            # and ./pass_times_200.sh in the background (about 35 minutes)
cd ../../part15/code && ./run_lit.sh      # 154 tests
```

## Chapter summary

- Chapter 39's open idea is **confirmed**: lowering `scf` to control flow from the last statement to the first removes the quadratic. On 64,000 synthetic loops the pass goes from 311.7 to 1.2 seconds; on the 200-step training program (190,636 nests in one function), from 2,106 to 3.1 seconds, with **no outlining**, and the whole compile takes 129 seconds with identical output.
- The instruction count of block splitting goes from ×4 per doubling to ×2.00: the mechanism Chapter 39 found is the thing removed.
- The output is byte-identical to MLIR's on 107 book programs, a 3,000-loop function and a hand-written function with `if`, `while` and nested loops.
- The pass costs about 1% more at small sizes and helps only with many top-level statements; it does **not** help a function whose loops are nested inside one outer loop.
- Seven broken passes are caught, and which check catches each is part of the result.

## Self-check questions

Each answer is collapsed; try the question first.

1. Why does lowering the loops from last to first avoid the quadratic?

    ??? note "Answer"
        Lowering a loop splits its block there and moves everything behind it. First to last, loop *i* has all the later unlowered nests behind it, so about *n*²/2 are moved in all. Last to first, what is behind a loop is already lowered (it left a branch and its blocks live elsewhere), so each split moves only the few operations between two loops.

2. The two wrong orders are caught only by the instruction count, not by any output check. Why?

    ??? note "Answer"
        MLIR's patterns give the same lowering of each loop whatever the order; only how long it takes differs. The output of a pass with the wrong order is still byte-identical. Only a measurement of cost can see that the speed-up has gone.

3. Why does the hand-written `edge_cases.mlir` matter when 107 book programs already agree?

    ??? note "Answer"
        The front end only produces plain loops, so none of the book's programs has a top-level `scf.if` or `scf.while`, or loops with results used later. The mutants that skip those statements are caught only by the hand-written file.

4. The new pass is about 1% more expensive at 2,000 loops. Why, and what does that say about when to use it?

    ??? note "Answer"
        It runs one conversion per top-level statement, and each conversion has a fixed price, while the quadratic part it removes is only 5% of the instructions at that size. It pays off for functions with many top-level loops (the gap opens from 4,000 loops) and costs a little for small ones, so it should be chosen by size or accepted as a small tax.

5. What does the nested-loops experiment show, and what would be needed to fix it?

    ??? note "Answer"
        One outer loop with *n* inner loops takes the same time under both passes (about 24 seconds at 16,000), because the pass reorders only top-level statements. Fixing it means lowering inner loops last to first as well, but a lowered inner loop leaves the outer loop's body with several blocks, which an `scf.for` cannot have, so the order of conversion has to change more than this pass does.

6. The 2,106-second figure should be read with care. Why?

    ??? note "Answer"
        It is one run, made while other work was running on the same four cores. It supports "about 35 minutes", consistent with the roughly 40 minutes Chapter 36 measured for compile and run together, not a figure to the second.

7. Name two things this chapter does not establish.

    ??? note "Answer"
        Any of: why the new pass and the control both grow by about 2.5× per doubling at the top of the table; why `clang -O0` is slower on outlined input; that the outputs match for every possible `scf` program; whether the same change would be accepted into MLIR; any benefit for loops nested in one body.
