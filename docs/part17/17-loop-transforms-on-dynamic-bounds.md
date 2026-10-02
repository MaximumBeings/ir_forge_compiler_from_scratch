# 17. Loop Transforms on Dynamic Bounds

**What you will understand:** whether Chapter 7's three loop transforms (fusion, tiling, unrolling) still work, and still give correct answers, when the loop bounds are not known until runtime. Chapter 13 made Mountain Goat handle dynamic shapes and listed this as untested; Chapter 16 listed it again among what the suite did not cover. The chapter runs nine transform variants on a dynamic program across eleven runtime shapes, checks every result against an independent computation, finds what each transform actually does to the IR, and explains the two places where a transform quietly does nothing. Every test, script, harness and IR listing is embedded from the repository.

**What you need to know first:** Chapter 7's transforms on static loops, Chapter 13's dynamic lowering (`memref.dim`, operand-bound loops) and Chapter 14's runtime shape check. New ground: how a loop transform copes with a trip count it cannot know.

!!! tip "Compile and run"
    Every command, listing and output on this page is reproduced by the commands in [Reproducing this chapter](#reproducing-this-chapter) at the bottom of the page, which also lists what must be built first. The chain of builds is in [Getting Started](../getting-started.md#which-build-does-each-chapter-need).


!!! note "Why this page shows FAIL lines, and why that is good"
    Parts of this page come from **negative controls**: the same tests run against an *older* build, or against *deliberately broken* code (a "mutation"). In those runs a **FAIL is the expected, wanted result**: it means a test noticed the problem, which is how we know the tests are worth anything. What would be wrong is the opposite, a deliberately broken build that passes everything. The **baseline** (the unmodified current build) must always show every test passing, and it does. Each script that does this says so in its own header and prints a reminder at the top of its output.

## Background: why a dynamic bound makes loop transforms harder

Chapter 7 transformed loops like `affine.for %i = 0 to 2`: the compiler knew the loop ran exactly twice. With dynamic shapes the bound is a value read at runtime: `affine.for %i = 0 to %dim`. Each transform leans on knowing the trip count in a different way, so each reacts differently:

| Transform | What it needs | What can go wrong with an unknown trip count |
|---|---|---|
| **Tiling** (split a loop into tile loops and point loops) | nothing about the count, but the last tile may be partial | the point loop must stop at the end of the data, not at the end of the tile, or it reads and writes out of bounds |
| **Partial unrolling** (repeat the body *k* times per iteration) | nothing about the count, but it may not be a multiple of *k* | the leftover iterations must still run, in an *epilogue* loop, or the tail of the array is skipped |
| **Full unrolling** (replace the loop with straight-line copies) | a **constant** trip count: you cannot emit "n copies" when n is unknown | it cannot apply at all |
| **Fusion** (merge two adjacent loop nests into one) | proof that the two nests cover the same iteration space and that merging preserves every data dependence | with symbolic bounds that proof may be impossible, and a cautious pass declines |

The first two are about **correctness at the boundary**: the answer must be right for sizes that do *not* divide the tile or unroll factor. The last two are about the transform **declining**, which is safe but means no optimization. Both kinds of behavior are measured below.

## The test program

An add followed by a transpose, with every dimension dynamic. It is the dynamic version of the Chapter 7 chain, and it produces two loop nests with an intermediate buffer between them:

```mlir
--8<-- "docs/part17/code/chain.mlir"
```

After `--convert-mg-to-affine` it becomes this, the **baseline** all transforms start from (`show/chain_affine.mlir`, 45 lines: Chapter 14's two runtime checks, a dynamically sized allocation, then the add nest, then the transpose nest):

??? note "Full baseline `chain_affine.mlir`"

    ```mlir
    --8<-- "docs/part17/code/show/chain_affine.mlir"
    ```

The part that matters is the two nests, each bounded by values read from the buffers' runtime sizes:

```mlir
--8<-- "docs/part17/code/show/chain_affine.mlir:20:40"
```

## How correctness is checked

A transform that keeps the program compiling proves little; the question is whether the numbers are right on awkward sizes. The harness computes `transpose(a + b)` directly in C for each shape and compares **every element** of the compiled function's result, exiting non-zero on any mismatch. The eleven shapes include ones chosen to break remainder handling: `1x1`, a single row, a single column, and sizes (`3x5`, `7x4`, `5x9`, `13x3`) that divide neither 2, 4 nor 16 evenly.

```c
--8<-- "docs/part17/code/chain_harness.c"
```

A second harness calls the same function with operands whose shapes **disagree**; Chapter 14's runtime check must abort it before any out-of-bounds load:

```c
--8<-- "docs/part17/code/chain_mismatch_harness.c"
```

`run_variants.sh` builds each variant to a native executable, runs both harnesses, and reports the transformed IR's loop count:

```sh
--8<-- "docs/part17/code/run_variants.sh"
```

## Results

The complete, unedited output of that script (`run_variants_out.txt`):

```text
--8<-- "docs/part17/code/run_variants_out.txt"
```

Reading it:

- **Every variant passes every shape.** Tiling at 2, 4 and 16 (16 is larger than most of the shapes, so there is a single partial tile), partial unrolling at 2 and 4, and tiling followed by unrolling all produced exactly the C answer on all eleven shapes.
- **The runtime check survives every transform.** The mismatch program aborts (exit 134) in all nine variants, including after tiling plus unrolling. Chapter 14 left open whether a loop transform could reorder or drop the `cf.assert`; on this program, it did not.
- **Two variants changed nothing.** `fusion` and `unroll_full` report `loops=4`, the same as the baseline. Section "Where a transform quietly does nothing" below shows that the IR is byte-identical.
- **The negative control fails as it should.** With every `arith.addf` rewritten to `arith.subf`, the harness reports `FAIL` and prints the first mismatch. This matters: without it, "all shapes pass" could only mean the harness never complains. (The control is applied to the baseline IR, not to a transform, so it shows the harness can fail, not that any transform is wrong.)

## Tiling: how the remainder is handled

With tile size 4 the add nest becomes the following (`show/chain_tile4.mlir`; the transpose nest is transformed identically). The two maps first, then the nest:

```mlir
--8<-- "docs/part17/code/show/chain_tile4.mlir:1:2"
```

```mlir
--8<-- "docs/part17/code/show/chain_tile4.mlir:23:34"
```

The outer two loops are the **tile loops**: they step through the data four at a time (`step 4`). The inner two are the **point loops**, each walking the elements inside one tile. The remainder is handled by the point loops' upper bound: `min #map1(%dim_6, %arg2)` means `min(%arg2 + 4, %dim_6)`, since `#map1 = (d0, d1) -> (d1 + 4, d0)` applied to `(%dim_6, %arg2)` gives `(%arg2 + 4, %dim_6)`. For all tiles but the last, the first term wins and the tile is full; for the last tile the second term wins and the loop stops at the end of the data. That `min` is what makes a 5x9 matrix, whose rows and columns are not multiples of 4, come out right.

The structure test pins exactly this shape (the map, `step 4` twice per nest, and a `min` bound on both point loops, for both nests), and a separate test runs the tiled program on all eleven shapes:

```mlir
--8<-- "docs/part15/code/test/dynamic-loops/tiling-structure.mlir"
```

```mlir
--8<-- "docs/part15/code/test/dynamic-loops/tiling-runs.mlir"
```

## Partial unrolling: the main loop and the epilogue

With `unroll-factor=2` the inner loop of the add nest becomes (`show/chain_unroll2.mlir`):

```mlir
--8<-- "docs/part17/code/show/chain_unroll2.mlir:1:3"
```

```mlir
--8<-- "docs/part17/code/show/chain_unroll2.mlir:23:42"
```

There are two loops where there was one. The **main loop** runs from 0 up to `(n floordiv 2) * 2` (`#map1`, `n` rounded down to a multiple of 2) in steps of 2, and its body holds two copies of the original work (lines 26 to 29 are the iteration at `%arg3`, lines 30 to 34 the one at `%arg3 + 1`, computed by `affine.apply #map2`). The **epilogue loop** then runs from where the main loop stopped up to `n`, one iteration at a time. For an even `n` the epilogue runs zero times; for an odd `n` it runs once. That is the same remainder idea as tiling's `min`, expressed as a second loop instead of a clipped bound.

```mlir
--8<-- "docs/part15/code/test/dynamic-loops/unroll-epilogue.mlir"
```

```mlir
--8<-- "docs/part15/code/test/dynamic-loops/unroll-runs.mlir"
```

## Where a transform quietly does nothing

### Full unrolling needs a constant trip count

Applied to the fully dynamic chain, `--affine-loop-unroll="unroll-full"` produced no error and no change. `fusion_probe.sh` and `show.sh` record that the output is byte-identical to the input:

```text
--8<-- "docs/part17/code/show/unroll_full_noop.txt"
```

That is the expected behavior (you cannot write out "n copies" for an unknown n) but it is worth seeing because the pass reports nothing: a script that assumed full unrolling had happened would be wrong without any diagnostic. With a **partially static** shape the same pass *does* work on the loop whose trip count is known. For `tensor<?x2xf64>` the add nest's inner loop runs exactly twice:

```mlir
--8<-- "docs/part17/code/chain2.mlir"
```

and full unrolling removed that loop (4 loops down to 3) and left the dynamic outer loop (`show/chain2_unroll_full.mlir`, add nest):

```mlir
--8<-- "docs/part17/code/show/chain2_unroll_full.mlir:17:27"
```

The two stores, `[%arg2, %c0]` and `[%arg2, %4]`, are the two unrolled iterations of the former inner loop, inside the surviving dynamic loop over rows. The transpose nest keeps its loops: its *outer* loop is the static one, and full unrolling only targets innermost loops (a Chapter 7 finding).

```mlir
--8<-- "docs/part15/code/test/dynamic-loops/unroll-full-needs-constant-trip-count.mlir"
```

### Fusion declines on dynamic bounds, and why that was narrowed down but not explained

`--affine-loop-fusion` left the dynamic chain alone (`show/fusion_noop.txt`):

```text
--8<-- "docs/part17/code/show/fusion_noop.txt"
```

An obvious guess is that the *transpose's* access pattern is the blocker, since Chapter 7 found that fusing add with transpose required permuting a loop. `fusion_probe.sh` tests that with three programs: the dynamic chain, a dynamic add followed by another add (no transpose, identical index patterns), and the same add-then-transpose chain with static 4x6 bounds:

```sh
--8<-- "docs/part17/code/fusion_probe.sh"
```

```text
--8<-- "docs/part17/code/fusion_probe_out.txt"
```

The result disproves the guess. The dynamic add-then-add chain is *also* left at 4 loops, while the static add-then-transpose chain fuses from 4 loops to 2. So the transpose is not what blocks fusion; **dynamic bounds are**, at least in this form. The static fused result, for comparison (`show/static_chain_fused.mlir`; note the intermediate buffer shrank to a 1x1 scalar slot, as in Chapter 7):

```mlir
--8<-- "docs/part17/code/show/static_chain_fused.mlir"
```

**Why** fusion declines was not established. Plausible explanations include that the intermediate buffer's size is dynamic, or that the dependence analysis cannot prove the two nests' symbolic iteration spaces equal; this chapter did not read the pass's source, as Chapter 12 did for other passes, and no test here distinguishes those explanations. The honest summary is a measured limitation without a verified cause. *(Update, added after Chapter 18: the cause is now established. The pass's profitability analysis requires a constant trip count for every loop in both nests; dynamic buffer shapes alone do not block fusion. Chapter 18 also found that tiling and then fusing dynamic loops produces invalid IR.)*

Two tests pin the pair: one asserts that fusion leaves the dynamic nests at four loops, with a header saying it is *designed to start failing* if a newer toolchain fuses them (in the same spirit as Chapter 16's crash test), and one asserts that the identical chain with static bounds does fuse, so the first test cannot pass merely because fusion is broken everywhere.

```mlir
--8<-- "docs/part15/code/test/dynamic-loops/fusion-declines.mlir"
```

```mlir
--8<-- "docs/part15/code/test/dynamic-loops/fusion-fires-when-static.mlir"
```

## The runtime check survives the transforms

Chapter 14 closed an out-of-bounds read with a `cf.assert` emitted before the loop, and noted it was untested whether a loop transform preserves it. The test applies tiling *and* unrolling together, builds the mismatch harness, and requires the process to abort, with the explanation visible under line-buffered output:

```mlir
--8<-- "docs/part15/code/test/dynamic-loops/runtime-check-survives-transforms.mlir"
```

This holds on this program for these transforms. It is an observation, not a proof: the assert is outside the loops, so tiling and unrolling, which rewrite loop nests, have no reason to touch it, and nothing here examines passes that could move or remove it.

## The tests, and whether they can fail

The suite grew from 34 tests (Chapter 16) to 42 with the eight above. The complete run (`run_out_42.txt`):

```text
--8<-- "docs/part15/code/run_out_42.txt"
```

Passing on a first run proves nothing, so `dynloops_mutation.sh` changes one thing in a copy of the suite per mutation and runs only the affected test. It carries forward the guard from Chapter 16 that rejects any mutation which changes the file's line count:

```sh
--8<-- "docs/part15/code/dynloops_mutation.sh"
```

```text
--8<-- "docs/part15/code/dynloops_mutation_out.txt"
```

All six mutations are caught: a changed tile size, a changed unroll factor, the "fusion declines" test fed the *static* chain (so fusion fires and the test fails, showing it really detects fusion firing), a harness whose expected value is wrong (so every shape fails), the partial-static unroll test fed the fully dynamic chain, and a mismatch harness changed to *match* (so nothing aborts). In the first run of this script, mutation 6 reported `NOT APPLIED`: it had been written with two `-e` expressions that the helper's single-expression interface mishandled. The script surfaced it instead of counting it as a pass; it was rewritten as one expression and rerun, and its diff is now exactly the two intended lines.

## What this does and does not establish

- **One program, two nests.** Everything above is the add-then-transpose chain and two sibling programs. Other op sequences were not tried.
- **Eleven shapes is a sample.** The shapes were chosen to include remainders, but eleven is not exhaustive, and very large sizes were not tried.
- **Correctness only, no performance.** Tiling and unrolling exist to make code faster, but nothing here was timed. A transform can be correct and slower; no claim about speed is made.
- **Fusion's cause is unexplained** *(update, added after Chapter 18: explained there)*, as stated above, and it is a limitation of this toolchain version's pass on this IR, not a statement about fusion in general.
- **Only Chapter 7's transforms.** No other affine passes (interchange, vectorization, loop-invariant code motion) were examined.
- **Rank 2 only,** as throughout since Chapter 13.
- **The GPU path was not run on dynamic shapes;** the bare-pointer option still requires static shapes (Chapter 12).
- **No CI.** The suite runs when someone runs it.

## Reproducing this chapter

```bash
../part14/code/build.sh          # the mg-opt under test (and: pip install lit)
cd docs/part17/code
./run_variants.sh   > run_variants_out.txt   # nine variants x eleven shapes, abort check, negative control
./fusion_probe.sh   > fusion_probe_out.txt   # narrowing down why fusion declined
./show.sh                                    # the IR listings above, under show/
cd ../part15/code
./run_lit.sh        > run_out_42.txt         # the 42-test suite
./dynloops_mutation.sh                       # the six mutations
```

Every file and output above is embedded from the repository when the site is built, so this page cannot drift from the code it describes. As in Chapters 10 through 16, no documentation was consulted for any claim: each result comes from running the commands.

## Chapter summary

This chapter settled whether Chapter 7's loop transforms survive dynamic bounds. Tiling (sizes 2, 4 and 16), partial unrolling (factors 2 and 4) and tiling plus unrolling all produced exactly the right answer on eleven runtime shapes, including shapes that divide neither the tile nor the unroll factor, because tiling clips each point loop with a `min` bound and unrolling adds an epilogue loop for the leftover iterations. Chapter 14's runtime shape check survived every transform. Two transforms quietly do nothing: full unrolling needs a constant trip count (and works on a loop whose count is static, such as the 2 in `?x2`), and fusion declines on dynamic bounds even for a plain add-then-add chain, while the same static add-then-transpose chain fuses from 4 loops to 2. The cause of the fusion limitation was narrowed (it is not the transpose) but not established. Eight new `lit` tests pin all of this and six mutations were all caught.

Deliberately out of scope, stated explicitly: nothing was timed, so no claim is made that any transform helps; only one program and Chapter 7's three transforms were examined; fusion's cause is unexplained; and the GPU path and rank other than 2 were not touched.

## Self-check questions

**1. Why must tiling clip its point loops with `min(arg + tile, n)`, and what would go wrong without the `min`?**

Worked answer: the tile loop steps through the data in strides of the tile size, but when `n` is not a multiple of the tile size the last tile is partial. A point loop running a fixed tile-size number of iterations would walk past the end of the data in that last tile, reading and writing out of bounds. The `min` bound makes the last tile stop at `n`. The chapter's evidence is the tiled IR (`min #map1(%dim_6, %arg2)`) and the passing results on `5x9`, `7x4`, `13x3` and other shapes that are not multiples of 4.

**2. What does the epilogue loop do after partial unrolling, and when does it run zero times?**

Worked answer: the main loop runs up to `(n floordiv k) * k`, `n` rounded down to a multiple of the unroll factor `k`, stepping by `k` with `k` copies of the body. The epilogue loop runs the remaining `n mod k` iterations one at a time. When `n` is already a multiple of `k` the main loop covers everything and the epilogue loop's range is empty, so it runs zero times. For `unroll-factor=2` that is every even `n`.

**3. Full unrolling produced no error and no change on the dynamic chain. Why is "no error" a trap, and how was the no-op demonstrated?**

Worked answer: a pass that declines to apply reports nothing, so a script or reader could assume the loops were unrolled when they were not. The chapter shows the output IR is byte-identical to the input (`cmp`), and the loop count stays at 4. The reason is that full unrolling must emit a fixed number of copies of the body, which needs a constant trip count; with a bound read from `memref.dim` there is none. With `tensor<?x2xf64>` the inner loop's count is the constant 2, and the same pass does unroll it (4 loops down to 3).

**4. A natural guess is that the transpose's access pattern stops `--affine-loop-fusion` on the dynamic chain. How did the chapter test that guess, and what was the answer?**

Worked answer: it ran fusion on three programs: the dynamic add-then-transpose chain, a dynamic add-then-add chain (identical index patterns, no transpose), and the same add-then-transpose chain with static 4x6 bounds. The dynamic add-then-add chain was also left at 4 loops, while the static add-then-transpose chain fused to 2. So the transpose is not the blocker; dynamic bounds are. The chapter then stops: it did not establish *why* dynamic bounds block fusion, and says no test distinguishes the candidate explanations. *(Update, added after Chapter 18: the pass requires constant trip counts for every loop in both nests, found by reading the source and confirmed with six experiments.)*

**5. Why does `fusion-declines.mlir` come with a companion test, `fusion-fires-when-static.mlir`, and what is the first test designed to do if the toolchain changes?**

Worked answer: the first test passes when fusion leaves the dynamic nests alone, which would also be true if fusion were simply broken everywhere. The companion shows the same chain with static bounds *does* fuse (4 loops to 2), so the first test is passing for the specific reason the chapter claims. The first test is also designed to start failing if a newer toolchain begins fusing dynamic nests: that is the signal to revisit this chapter's finding, not a regression in the book.
