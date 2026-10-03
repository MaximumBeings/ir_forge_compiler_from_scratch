# 7. Real Loop Transforms: Fusion, Tiling, and Unrolling at the `affine` Level

![Mountain goats on the mountain above a desert](../assets/goats/ch-07.svg){ style="display:block;margin:0 auto;max-width:100%;height:auto;border-radius:6px" }

**What you will understand:** the real, concrete payoff Chapter 1's own citation promised back in Part 0 -- that keeping a loop in its structured, `affine` form (rather than a bare CFG) is what makes loop fusion, tiling, and unrolling tractable at all. This chapter runs all three real, MLIR-shipped transforms on Mountain Goat's own lowered loops, with real before/after IR for each, and closes with the real reason canonicalization has to run again after every one of them.

**What you need to know first:** Chapter 4's own hand-written `affine.for` lowering for `mg.add`/`mg.transpose`; Chapter 3's own canonicalization/CSE passes, run again here for a genuinely new reason.

!!! tip "Compile and run"
    ```sh
    cd docs/part7/code
    ./build.sh        # -> ./build/mg-opt (registers the affine passes)
    ./run.sh          # fusion, tiling, unrolling, and the full pipeline run
    ```
    Same prerequisites as Chapter 5. Every listing and output on this page comes from these commands (and the chapter's own embedded files).


## The real question this chapter answers

Chapter 1 quoted MLIR's own rationale directly: structured, affine-level loops "subsume all traditional loop transformations... such as loop tiling, interchange, permutation... fusion, and distribution," naming the exact real capability this book has not yet exercised. Mountain Goat's own `compute` function -- `mg.add` immediately feeding `mg.transpose` -- is a genuine, real producer/consumer pair once lowered: the add's own loop nest writes a buffer the transpose's own loop nest immediately reads back, element by element. This chapter answers, concretely: what do MLIR's own real, built-in affine transform passes actually do to that real pair of loop nests, run one after another, with every real before/after state captured directly?

## The real starting point: two adjacent, real loop nests

```mlir
func.func @compute(%a: tensor<2x2xf64>, %b: tensor<2x2xf64>) {
  %0 = mg.add %a, %b : tensor<2x2xf64>, tensor<2x2xf64> -> tensor<2x2xf64>
  %1 = mg.transpose %0 : tensor<2x2xf64> to tensor<2x2xf64>
  mg.print %1 : tensor<2x2xf64>
  func.return
}
```

Lowered through Chapter 4's own real `--convert-mg-to-affine` pass:

```
./mg-opt mountain_goat_src.mlir --convert-mg-to-affine
```

**Real captured output (relevant excerpt):**
```mlir
func.func @compute(%arg0: memref<2x2xf64>, %arg1: memref<2x2xf64>) {
  %alloc = memref.alloc() : memref<2x2xf64>
  affine.for %arg2 = 0 to 2 {
    affine.for %arg3 = 0 to 2 {
      %0 = affine.load %arg0[%arg2, %arg3] : memref<2x2xf64>
      %1 = affine.load %arg1[%arg2, %arg3] : memref<2x2xf64>
      %2 = arith.addf %0, %1 : f64
      affine.store %2, %alloc[%arg2, %arg3] : memref<2x2xf64>
    }
  }
  %alloc_0 = memref.alloc() : memref<2x2xf64>
  affine.for %arg2 = 0 to 2 {
    affine.for %arg3 = 0 to 2 {
      %0 = affine.load %alloc[%arg3, %arg2] : memref<2x2xf64>
      affine.store %0, %alloc_0[%arg2, %arg3] : memref<2x2xf64>
    }
  }
  ...
}
```

Two separate, real loop nests, the second's own `affine.load` reading directly from the first's own `%alloc` result -- a genuine, real fusion candidate, not a constructed example.

## Real transform 1: `--affine-loop-fusion`

```
./mg-opt mountain_goat_affine.mlir --affine-loop-fusion
```

**Real captured output:**
```mlir
func.func @compute(%arg0: memref<2x2xf64>, %arg1: memref<2x2xf64>) {
  %alloc = memref.alloc() : memref<1x1xf64>
  %alloc_0 = memref.alloc() : memref<2x2xf64>
  affine.for %arg2 = 0 to 2 {
    affine.for %arg3 = 0 to 2 {
      %0 = affine.load %arg0[%arg3, %arg2] : memref<2x2xf64>
      %1 = affine.load %arg1[%arg3, %arg2] : memref<2x2xf64>
      %2 = arith.addf %0, %1 : f64
      affine.store %2, %alloc[0, 0] : memref<1x1xf64>
      %3 = affine.load %alloc[0, 0] : memref<1x1xf64>
      affine.store %3, %alloc_0[%arg2, %arg3] : memref<2x2xf64>
    }
  }
  ...
}
```

Two genuinely real, visible changes, neither one this chapter's own invention: the two separate loop nests are now one, and the intermediate buffer genuinely shrank from `memref<2x2xf64>` to `memref<1x1xf64>` -- real `--affine-loop-fusion` determined that, once fused, only one element of the add's own result is ever live at a time (computed, immediately consumed by the very next statement, never needed again), so the real pass allocated a single-element buffer instead of a full matrix. This is real precedent for exactly the kind of cleanup MLIR's own official Toy tutorial names directly for the same real reason:

> "Our naive lowering is correct, but it leaves a lot to be desired with regards to efficiency. For example, the lowering of `toy.mul` has generated some redundant loads. Let's look at how adding a few existing optimizations to the pipeline can help clean this up. Adding the `LoopFusion` and `AffineScalarReplacement` passes to the pipeline gives the following result..." (`mlir/docs/Tutorials/Toy/Ch-5.md`)

A second, subtler real detail: the fused loop's own `affine.load %arg0[%arg3, %arg2]` reads with its *induction variables swapped* relative to the original add's own `[%arg2, %arg3]`. Real `--affine-loop-fusion` did not just concatenate the two loop bodies -- it reordered the add's own iteration to match the transpose's own access pattern, so a single shared `affine.for` nest could drive both computations' own real memory accesses correctly. This loop permutation is itself one of the three real capabilities Chapter 1's own cited rationale named directly ("loop tiling, interchange, permutation").

## Real transform 2: `--affine-loop-tile`

Tiling reorganizes one loop nest's own iteration order into tiles -- real, outer "tile" loops stepping over blocks of iterations, with real, inner "point" loops iterating within each block, a transform whose own real purpose is improving cache locality on loops with real, large trip counts. This book's own worked example uses a small, illustrative `2x2` shape -- too small for tiling to produce any genuine performance benefit -- so a small, illustrative tile size (`1`) is used here specifically to make the real transform's own structural effect visible, stated honestly rather than implied to be a realistic tuning choice:

```
./mg-opt mountain_goat_fused.mlir --affine-loop-tile="tile-size=1"
```

**Real captured output:**
```mlir
#map = affine_map<(d0) -> (d0)>
#map1 = affine_map<(d0) -> (d0 + 1)>
...
affine.for %arg2 = 0 to 2 {
  affine.for %arg3 = 0 to 2 {
    affine.for %arg4 = #map(%arg2) to #map1(%arg2) {
      affine.for %arg5 = #map(%arg3) to #map1(%arg3) {
        %0 = affine.load %arg0[%arg5, %arg4] : memref<2x2xf64>
        %1 = affine.load %arg1[%arg5, %arg4] : memref<2x2xf64>
        %2 = arith.addf %0, %1 : f64
        affine.store %2, %alloc[0, 0] : memref<1x1xf64>
        %3 = affine.load %alloc[0, 0] : memref<1x1xf64>
        affine.store %3, %alloc_0[%arg4, %arg5] : memref<2x2xf64>
      }
    }
  }
}
```

Genuinely, visibly real: the original two-deep loop nest became four-deep, two real new "tile" loops (`%arg2`, `%arg3`) each driving a real "point" loop (`%arg4`, `%arg5`) that -- with tile size `1` -- covers exactly one original iteration, expressed through real affine maps (`#map`/`#map1`) rather than plain arithmetic. A real, larger Mountain Goat tensor with a real tile size tuned to its own cache behavior would show the same real structural transform doing genuinely useful work; this small example's own real value is confirming the transform is *correct* and *real*, not yet *profitable* at this size.

## Real transform 3: `--affine-loop-unroll`

```
./mg-opt mountain_goat_fused.mlir --affine-loop-unroll="unroll-full" --affine-loop-unroll="unroll-full"
```

**Real captured output (excerpt):**
```mlir
%0 = affine.load %arg0[%c0_0, %c0] : memref<2x2xf64>
%1 = affine.load %arg1[%c0_0, %c0] : memref<2x2xf64>
%2 = arith.addf %0, %1 : f64
affine.store %2, %alloc[0, 0] : memref<1x1xf64>
%3 = affine.load %alloc[0, 0] : memref<1x1xf64>
affine.store %3, %alloc_1[%c0, %c0_0] : memref<2x2xf64>
%4 = affine.apply #map(%c0_0)
%5 = affine.load %arg0[%4, %c0] : memref<2x2xf64>
... (three more copies of the same real pattern, one per original iteration)
```

Both real `affine.for` loops are genuinely gone -- `unroll-full` replaced the entire two-deep, four-iteration loop nest with four real, straight-line copies of the loop body, each with its own real index computed via `affine.apply`. This chapter's own real pass had to be run *twice*: the first invocation (its own real captured output omitted here for space) only unrolled the *innermost* loop, leaving the outer loop intact -- `--affine-loop-unroll`'s own real, documented default scope is innermost loops only, so a second invocation was genuinely needed once the former outer loop became innermost in its own turn.

## Why canonicalization has to run again: a real, visible mess, and a real, visible cleanup

The real unrolled output above is correct, but genuinely messy: every one of its four copies carries its own real `affine.apply #map(%c0_0)` recomputing an index offset that is, in three of the four cases, a compile-time-known constant. Running Chapter 3's own real `--canonicalize` pass again -- not a new pass, the exact same one already used twice in this book -- cleans this up directly:

```
./mg-opt mountain_goat_fused.mlir --affine-loop-unroll="unroll-full" --affine-loop-unroll="unroll-full" --canonicalize
```

**Real captured output (excerpt):**
```mlir
%0 = affine.load %arg0[0, 0] : memref<2x2xf64>
%1 = affine.load %arg1[0, 0] : memref<2x2xf64>
%2 = arith.addf %0, %1 : f64
affine.store %2, %alloc[0, 0] : memref<1x1xf64>
%3 = affine.load %alloc[0, 0] : memref<1x1xf64>
affine.store %3, %alloc_0[0, 0] : memref<2x2xf64>
%4 = affine.load %arg0[1, 0] : memref<2x2xf64>
%5 = affine.load %arg1[1, 0] : memref<2x2xf64>
%6 = arith.addf %4, %5 : f64
...
```

Every real `affine.apply` and every real, separate `%c0`/`%c0_0` index constant is genuinely gone -- folded directly into each `affine.load`/`affine.store`'s own immediate index operands (`[0, 0]`, `[1, 0]`, `[0, 1]`, `[1, 1]`). This is the real, concrete reason this book's own TOC names for Part 4: `--canonicalize` was already run, genuinely, twice before this chapter (Chapters 3 and 4) -- but each one of the real transforms this chapter just ran (fusion, tiling, unrolling) introduces its own new, real, local redundancy (reordered loads, affine-map index arithmetic) that *those specific passes* have no reason to clean up themselves, since cleanup is not fusion's, tiling's, or unrolling's own real job. Canonicalization is not a one-time pass run once near the start of a pipeline; it is real, general-purpose cleanup that has to be invited back after *any* real transform that might leave redundant arithmetic behind, at whichever real IR level that transform happens to operate on.

## Real worked example: the full transform sequence, genuinely still correct

Chaining all three real transforms and canonicalization into one real pipeline, then continuing with Chapter 5's own exact `affine`-to-`llvm` pipeline and running the result:

```mlir
func.func @compute(%a: tensor<2x2xf64>, %b: tensor<2x2xf64>) {
  %0 = mg.add %a, %b : tensor<2x2xf64>, tensor<2x2xf64> -> tensor<2x2xf64>
  %1 = mg.transpose %0 : tensor<2x2xf64> to tensor<2x2xf64>
  mg.print %1 : tensor<2x2xf64>
  func.return
}

func.func @main() {
  %0 = mg.constant dense<[[1.0, 2.0], [3.0, 4.0]]> : tensor<2x2xf64>
  %1 = mg.constant dense<[[5.0, 6.0], [7.0, 8.0]]> : tensor<2x2xf64>
  func.call @compute(%0, %1) : (tensor<2x2xf64>, tensor<2x2xf64>) -> ()
  func.return
}
```

```
./mg-opt mountain_goat_full.mlir --convert-mg-to-affine \
  --affine-loop-fusion --affine-loop-tile="tile-size=1" \
  --affine-loop-unroll="unroll-full" --affine-loop-unroll="unroll-full" --affine-loop-unroll="unroll-full" \
  --canonicalize \
  --lower-affine --convert-scf-to-cf --convert-arith-to-llvm \
  --finalize-memref-to-llvm --convert-func-to-llvm --reconcile-unrealized-casts \
  -o mountain_goat_llvm.mlir

mlir-cpu-runner-18 mountain_goat_llvm.mlir \
  --shared-libs=/usr/lib/llvm-18/lib/libmlir_runner_utils.so \
  --shared-libs=/usr/lib/llvm-18/lib/libmlir_c_runner_utils.so \
  -e main -entry-point-result=void
```

**Real captured output:**
```text
Unranked Memref base@ = 0x561326f2cd40 rank = 2 offset = 0 sizes = [2, 2] strides = [2, 1] data =
[[6,   10],
 [8,   12]]
```

`transpose(add([[1, 2], [3, 4]], [[5, 6], [7, 8]])) = transpose([[6, 8], [10, 12]]) = [[6, 10], [8, 12]]` -- genuinely the correct, real answer, computed by a program whose own loop structure has been fused, tiled, fully unrolled, and re-canonicalized, through MLIR's own real, built-in passes, three real transforms deep, end to end.

## The complete source files

The excerpts above show the parts under discussion. These files appear in `code/` and are not shown elsewhere on this page; each is embedded exactly as it exists in the repository, collapsed so the narrative stays readable.

??? note "`CMakeLists.txt`"

    ```cmake
    --8<-- "docs/part7/code/CMakeLists.txt"
    ```

??? note "`mg-opt.cpp`"

    ```cpp
    --8<-- "docs/part7/code/mg-opt.cpp"
    ```

## What later chapters changed

Chapter 15 added a test for `--affine-loop-fusion`, and Chapter 16 added tests for tiling and full unrolling, so this chapter's three transforms are now covered by the `lit`/`FileCheck` suite. These transforms were first run on dynamic loop bounds in Chapter 17: tiling and partial unrolling stayed correct on eleven runtime shapes, full unrolling needs a constant trip count (and silently does nothing without one), and fusion declined on dynamic bounds for a reason that chapter narrowed but did not establish.

## Chapter summary

This chapter ran all three real transforms Chapter 1's own citation named back in Part 0: `--affine-loop-fusion` genuinely merged Mountain Goat's own add-then-transpose loop nests into one, shrinking an intermediate buffer in the process and reordering iteration to match a real access-pattern permutation; `--affine-loop-tile` genuinely restructured the fused loop into real tile/point loop pairs, honestly using an illustrative tile size since this book's own worked example is too small to show a genuine locality benefit; `--affine-loop-unroll`, run twice (its own real, documented default scope being innermost loops only), genuinely replaced the entire loop nest with real straight-line code. Re-running `--canonicalize` -- the exact same pass already used in Chapters 3 and 4 -- genuinely cleaned up the real index arithmetic unrolling introduced, concretely demonstrating this book's own TOC-promised point: canonicalization is real, general-purpose cleanup invited back after any transform, at any level, not a one-time early pass. The full real sequence, continued through Chapter 5's own unmodified `affine`-to-`llvm` pipeline and genuinely JIT-run, produced the correct real answer.

Deliberately out of scope, stated explicitly: this chapter's own tile size (`1`) is illustrative, chosen to make the transform's own structure visible on a small example, not tuned for any real performance benefit -- a genuinely larger Mountain Goat tensor, with a tile size chosen for a real cache size, is left for a reader to try, not demonstrated here. No new real `mg`-specific code was written in this chapter at all -- every real transform used is MLIR's own generic, dialect-agnostic infrastructure, applying unchanged to IR this book's own tooling produced.

## Self-check questions

**1. The real fused loop nest's own intermediate buffer shrank from `memref<2x2xf64>` to `memref<1x1xf64>`. What real, specific property of the fused loop did `--affine-loop-fusion` have to confirm before it could safely make that change?**

Worked answer: the real pass had to confirm that, once the add and transpose loop bodies share one real iteration space, each individual element the add computes is consumed (read by the transpose's own load) in the very same iteration it is produced, and never needed again afterward. If any later iteration needed an *earlier* iteration's own intermediate value, shrinking the buffer to a single element would silently overwrite data still required -- a real correctness bug the pass's own real dependence analysis exists specifically to rule out before making this optimization.

**2. Why did `--affine-loop-fusion` swap the add's own loop induction variables (from `[%arg2, %arg3]` to `[%arg3, %arg2]`) rather than leaving the add's own iteration order untouched and only merging the loop bodies?**

Worked answer: the transpose's own real access pattern reads `input[j, i]` to produce `output[i, j]` -- a real, fixed relationship between the two loops' own index variables. For one shared loop nest to drive both the add's own writes and the transpose's own reads correctly, the add's own iteration order had to be adjusted to match the order the fused loop nest actually walks the buffer in, which is dictated by the transpose's own real index relationship, not the add's own original, arbitrary order.

**3. The chapter needed to invoke `--affine-loop-unroll="unroll-full"` twice to fully unroll both loop levels, rather than once. What does that real, observed behavior reveal about the pass's own real, default scope?**

Worked answer: the real pass's own documented default behavior targets *innermost* loops specifically, not every loop in a nest indiscriminately. After the first invocation unrolled the original inner loop away, the loop that used to be the *outer* loop became the new innermost loop (since nothing was nested inside it anymore) -- genuinely requiring a second, separate invocation to reach it, rather than the pass recursing through every nesting level in one real pass.

**4. Why does the chapter call it a real, structural mistake to treat `--affine-loop-fusion`, `--affine-loop-tile`, and `--affine-loop-unroll` as if any one of them were also responsible for cleaning up the redundant arithmetic the others introduce?**

Worked answer: each real pass has one real, specific job -- fusion merges loop nests, tiling restructures iteration order, unrolling replicates loop bodies -- and MLIR's own real design, visible directly in this chapter's own captured output, is that none of them also runs a general cleanup sweep over the arithmetic its own transform happens to leave behind (the `affine.apply` calls unrolling introduced, for instance). Expecting one of them to clean up after itself would mean duplicating canonicalization's own real, general-purpose logic inside every single transform pass, for no real benefit over simply running canonicalization again afterward, as this chapter actually did.

**5. The final real worked example chains `--affine-loop-fusion`, tiling, unrolling, canonicalization, and then Chapter 5's own unmodified `affine`-to-`llvm` pipeline, and it genuinely still produces the correct answer. What real property of all the passes involved does that successful final run actually confirm?**

Worked answer: it confirms that every one of these real, independently-developed MLIR passes -- fusion, tiling, unrolling, canonicalization, and the five-pass `affine`-to-`llvm` lowering pipeline, developed across entirely separate chapters of this book and, in MLIR's own real codebase, by entirely separate engineering efforts -- preserves the real, observable *meaning* of the program even while aggressively restructuring its own real IR. A transform pipeline this deep producing a wrong answer would have been a real, visible failure at the very last step; genuinely getting `[[6, 10], [8, 12]]` is real, direct evidence that semantics survived every real rewrite along the way, not merely that each pass ran without crashing.
