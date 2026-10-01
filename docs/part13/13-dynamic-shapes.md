# 13. Dynamic Shapes: Closing Chapter 12's Biggest Unknown

**What you will understand:** what actually happens when Mountain Goat meets a tensor whose size is not known until runtime (`tensor<?x?xf64>`), what broke, how it was fixed on *both* of this book's lowering paths, and what is still not safe. Chapter 12 listed "dynamic shapes are untested" as the largest unknown about this compiler; this chapter turns that unknown into measured facts.

**What you need to know first:** Chapter 3's verifiers and canonicalizer, Chapter 4/5's hand-written `--convert-mg-to-affine`, Chapter 6's bufferization models, and Chapter 8's calling convention. New ground: `?` dimensions, `memref.dim`, and dynamic `memref.alloc`.

## Step 1: predict, then test

Reading the Chapter 5 and 6 lowering code before running anything, the prediction was: the verifiers accept `?` (a plain `getShape()` comparison treats `-1 == -1`), but the lowerings pass `shape[0]` straight into a loop bound and allocate `memref<?x?xf64>` with no size operands. Results of the first real run, with an unmodified `mg-opt` rebuilt from Chapters 3 through 7's own files:

| Input | Result |
|---|---|
| `mg.add` and `mg.transpose` on `tensor<?x?xf64>`, parse + verify | accepted |
| `mg.add` of `tensor<?x2xf64>` and `tensor<3x2xf64>` | **rejected**: `operands must have the same shape` |
| `--convert-mg-to-affine` on the dynamic `mg.add` | `error: 'memref.alloc' op dimension operand count does not equal memref dynamic dimension count` |
| `--one-shot-bufferize` (Chapter 6) on the same program | the identical `memref.alloc` error |

So: the prediction held for the lowerings, and the verifier turned out to be wrong in a way the prediction missed: `?x2` and `3x2` can be equal at runtime, and the plain equality check rejects them. The lowering failures are **loud**, which is the good kind: the verifier on `memref.alloc` caught what would otherwise have been loops with a `-1` upper bound.

## Step 2: the fix, in one shared header

All three lowering sites (Chapter 5's `AddOpLowering` and `TransposeOpLowering`, Chapter 6's two bufferization models) had the same shape of code, so the fix lives in one new header, `DynamicShapes.h`:

- `compatibleDim(a, b)`: two extents are compatible if equal or if either is `?`.
- `extentOf(...)`: a real `memref.dim` reading a buffer's runtime size along one dimension.
- `allocFor(...)`: `memref.alloc` with a size operand for each dynamic dimension.
- `nest2D(...)`: the loop nest. **A fully static shape takes exactly the old constant-bound call**, so earlier chapters' output cannot change; a shape with a `?` takes the operand-bound path.

For `mg.add` the result's dynamic extents are read from the left operand (`memref.dim %lhs`); for `mg.transpose` the result's extent along dimension *d* is the input's extent along *1 − d*. The unified diff against Chapters 3, 5 and 6 is `code/chapter13.diff` (160 lines). The result for a dynamic add:

```mlir
func.func @add_dyn(%arg0: memref<?x?xf64>, %arg1: memref<?x?xf64>) -> memref<?x?xf64> {
  %c0 = arith.constant 0 : index
  %dim = memref.dim %arg0, %c0 : memref<?x?xf64>
  %c1 = arith.constant 1 : index
  %dim_0 = memref.dim %arg0, %c1 : memref<?x?xf64>
  %alloc = memref.alloc(%dim, %dim_0) : memref<?x?xf64>
  %c0_1 = arith.constant 0 : index
  affine.for %arg2 = #map(%c0_1) to #map(%dim) {
    affine.for %arg3 = #map(%c0_1) to #map(%dim_0) {
      %0 = affine.load %arg0[%arg2, %arg3] : memref<?x?xf64>
      %1 = affine.load %arg1[%arg2, %arg3] : memref<?x?xf64>
      %2 = arith.addf %0, %1 : f64
      affine.store %2, %alloc[%arg2, %arg3] : memref<?x?xf64>
    }
  }
  return %alloc : memref<?x?xf64>
}
```

Real `memref.dim`, a real dynamic `memref.alloc(%dim, %dim_0)`, and loops bounded by those values. The verifiers were also relaxed to `compatibleDim`.

## Step 3: two more bugs that dynamic shapes exposed

Testing edge cases found two problems neither the chapter-3 author's static examples nor the prediction anticipated:

1. **The canonicalizer produced invalid IR.** Chapter 3's `SimplifyRedundantTranspose` rewrites `transpose(transpose(x))` to `x` unconditionally. With `x : tensor<?x2xf64>` and an outer result type of `tensor<?x?xf64>`, replacing the result with `x` changes the type, and `mlir-opt` then reports `type of return operand 0 ('tensor<?x2xf64>') doesn't match function result type ('tensor<?x?xf64>')`. The fix is conservative: the pattern now fires only when `x`'s type equals the result type exactly. The alternative (inserting a `tensor.cast`) would pull in another dialect. Check: exact types still fold (`tt2.mlir` reduces to `return %arg0`); mixed types are left alone.
2. **The verifiers cast unranked tensors without checking.** `F64Tensor` also accepts `tensor<*xf64>`, and both verifiers used `llvm::cast<RankedTensorType>`. In a release build (no assertions) that cast does not check anything. The unmodified build printed a sensible-looking `only supports rank-2 tensors` for an unranked transpose, but reading the code shows that was luck, not design. Both now use `dyn_cast` and emit an explicit `only supports ranked tensors`.

## Step 4: run it for real, on non-square shapes

The dynamic program (`both.mlir`: `@add_dyn` and `@t_dyn`) went through **both** paths to native code: Chapter 4/5's `--convert-mg-to-affine`, and Chapter 6's `--one-shot-bufferize="bufferize-function-boundaries"`, each followed by the same five-pass lowering and `mlir-translate-18`/`clang-18`, linked with a C harness (`harness_dyn.c`) that fills the same rank-2 descriptor Chapter 8 used with runtime sizes. Both binaries printed identical, correct output:

```text
add 2x3 -> 2x3:        11 22 33 / 44 55 66
add 3x2 -> 3x2:        11 22 / 33 44 / 55 66
add 1x6 -> 1x6:        11 22 33 44 55 66
transpose 2x3 -> 3x2:  1 4 / 2 5 / 3 6
transpose 1x6 -> 6x1:  1 / 2 / 3 / 4 / 5 / 6
```

(Rows joined with `/` here for space; `code/run_out.txt` has the real layout.) **One compiled function handled five different shapes**, which is the point of dynamic shapes, and a transposed result had a different shape from its input at runtime.

### The strided-view test: where the two paths really differ

Chapter 6 noted that bufferization's function arguments are *strided* memrefs (`memref<?x?xf64, strided<[?, ?], offset: ?>>`) while Chapter 4's are plain row-major; here that difference becomes observable. Path B was also called with the same six numbers described as a **column-major** 2x3 matrix (strides `(1, 2)`), whose logical value is `[[1,3,5],[2,4,6]]`:

```text
transpose 2x3 column-major view -> 3x2:
1 2
3 4
5 6
```

That is the correct transpose of the logical matrix. Path A cannot be given this test fairly: its argument type is `memref<?x?xf64>` with the default row-major layout, so a caller passing different strides would be violating that type's contract. The finding is not that A is wrong; it is that **B's types carry strides and A's do not**, which is a real capability difference between the two paths that static 2x2 examples could never show.

### Static regression

`--convert-mg-to-affine` on Chapter 10's static `add_tensors.mlir` is **byte-identical** to Chapter 10's stored `add_affine.mlir` (`cmp` reports no difference). Chapter 8's static `add_tensors` run natively through both paths, with Chapter 8's own harness, still prints `[[6, 8], [10, 12]]`. Chapter 3's canonicalize demo still folds to the same two-operation program.

## What is still not safe

**Runtime shape mismatch is silent memory corruption.** *(Update, added after Chapter 14: closed for `mg.add`. The dynamic add now aborts on a runtime mismatch instead of reading out of bounds; see Chapter 14. The description below is the state when this chapter was written.)* The verifier can only compare shapes it knows at compile time. Called through the dynamic function with `a` as 2x3 and `b` as 1x2 (a buffer holding two doubles), the add runs to completion and returns garbage:

```text
result 2x3: 11 22 4 5 7 9
```

The loop bounds come from `a`; the loads from `b` run off the end of its two-element buffer and read whatever sits beyond it. There is no runtime check. That `11 22` is right (the first two elements exist in both) and `4 5 7 9` is not meaningful, and **the values after the first two are not guaranteed to be reproducible**: they are whatever happened to be in memory (they came out identical across the two runs made for this chapter, which proves nothing about other builds or machines). This is an out-of-bounds read, so it is undefined behavior, and a different run or build could crash instead. Closing it means emitting a runtime comparison of the operands' `memref.dim`s and aborting on mismatch (e.g. a `cf.assert`); this chapter did not do that, because it also needs to confirm the `cf` lowering is present in the five-pass pipeline, and that is a separate piece of verified work. Mountain Goat is **not memory safe** for dynamic shapes until then.

Also still open:

- **Only rank 2.** The verifiers and loops are hard-wired to two dimensions; a rank-3 tensor is rejected by the verifier, which is correct but means dynamic *rank* is out of scope.
- **`mg.constant` stays static.** A literal's shape is always known, so this is by design, not a gap.
- **Chapter 7's loop transforms and Chapters 10 through 12's GPU path were not re-run on dynamic shapes.** Fusion, tiling and unrolling with a `?` bound are untested; full unrolling in particular cannot work without a constant trip count. The GPU path's `bare-ptr` option requires static shapes (Chapter 12), so dynamic-shape GPU lowering was not attempted.
- **No automated tests.** As Chapter 12 found, this repository has none; `code/run_tests.sh` is a script that prints results for a human to read, not an assertion-based suite. Writing real `lit`/`FileCheck` tests remains an open candidate chapter.

## Reproducing this chapter

```bash
cd docs/part13/code
./build.sh        # assembles the tree from the earlier chapters' files plus this chapter's four, builds ./build/mg-opt
./run_tests.sh    # runs every check above; output matches run_out.txt
```

Both scripts were run from this state (after the build directories were removed) and `run_out.txt` is their unedited output; `build/`, `tree/` and `work/` are git-ignored. Needs `mlir-18-tools`, `libmlir-18-dev`, `llvm-18-dev`, `cmake`, `clang-18`. As in Chapters 10 through 12, no documentation pages were consulted; every claim comes from running the code or reading it.
