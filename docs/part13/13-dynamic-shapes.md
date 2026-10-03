# 13. Dynamic Shapes: Closing Chapter 12's Biggest Unknown

![Mountain goats in space helmets on Mars](../assets/goats/ch-13.svg){ style="display:block;margin:0 auto;max-width:100%;height:auto;border-radius:6px" }

**What you will understand:** what actually happens when Mountain Goat meets a tensor whose size is not known until runtime (`tensor<?x?xf64>`), what broke, how it was fixed on *both* of this book's lowering paths, and what is still not safe. Chapter 12 listed "dynamic shapes are untested" as the largest unknown about this compiler; this chapter turns that unknown into measured facts. The page shows the old code that carried the hazard, the real error output of the unmodified compiler, the new helper and the complete diff, and the real output of every test, so nothing has to be taken on trust.

**What you need to know first:** Chapter 3's verifiers and canonicalizer, Chapter 4/5's hand-written `--convert-mg-to-affine`, Chapter 6's bufferization models, and Chapter 8's calling convention. New ground: `?` dimensions, `memref.dim`, and dynamic `memref.alloc`.

!!! tip "Compile and run"
    Every command, listing and output on this page is reproduced by the commands in [Reproducing this chapter](#reproducing-this-chapter) at the bottom of the page, which also lists what must be built first. The chain of builds is in [Getting Started](../getting-started.md#which-build-does-each-chapter-need).


!!! note "Why this page shows FAIL lines, and why that is good"
    Parts of this page come from **negative controls**: the same tests run against an *older* build, or against *deliberately broken* code (a "mutation"). In those runs a **FAIL is the expected, wanted result**: it means a test noticed the problem, which is how we know the tests are worth anything. What would be wrong is the opposite, a deliberately broken build that passes everything. The **baseline** (the unmodified current build) must always show every test passing, and it does. Each script that does this says so in its own header and prints a reminder at the top of its output.

## Background: static and dynamic shapes

Every example in Chapters 1 through 12 uses shapes written into the program: `tensor<2x2xf64>` means exactly four doubles, and the compiler knows that while it compiles. A **dynamic** extent is written `?`: `tensor<?x?xf64>` is a rank-2 tensor whose two sizes are only known when the program runs, so one compiled function can serve a 2x3 input and a 1x6 input. Three consequences drive everything in this chapter:

- **A `?` is not a number.** Code that reads `shape[0]` from the type gets `-1` (MLIR's sentinel for "dynamic"), not a size. To loop over a dynamic dimension the compiler must emit code that *reads the size at runtime*: the `memref.dim` operation.
- **Allocation needs the sizes too.** `memref.alloc()` of a `memref<?x?xf64>` must be given one size operand per `?`; a bare `memref.alloc()` is invalid.
- **Two `?`s are not known to be equal.** `tensor<?x2xf64>` and `tensor<3x2xf64>` can agree at runtime (when the `?` is 3), so a verifier that rejects them is too strict, and a verifier that accepts `?x?` against `?x?` cannot know whether they agree at all (Chapter 14's subject).

Separately, MLIR distinguishes **ranked** tensors (the number of dimensions is known, even if their sizes are not) from **unranked** ones (`tensor<*xf64>`, not even the rank is known). `mg` only supports ranked ones; the question is how loudly it says so.

## Step 1: predict, then test

Before running anything, Chapter 5's own lowering code was read. The `mg.add` pattern, which both Chapter 4's hand-written pass and (in a different form) Chapter 6's bufferization carry:

```cpp
--8<-- "docs/part5/code/LowerToAffine.cpp:75:104"
```

The hazard is on lines 84 to 91: `tensorType.getShape()` returns `-1` for a `?`, that value goes straight into `buildAffineLoopNest` as a loop bound, and `memref.alloc` is given no size operands. The verifiers were also read (Chapter 3's originals):

```cpp
--8<-- "docs/part3/code/MgDialect.cpp:45:64"
```

The prediction: the verifiers compare shapes with `!=`, which treats `-1 == -1` as equal, so they accept `?x?` against `?x?`; the lowerings fail. The first real run used an **unmodified** `mg-opt`, the Chapter 7 build, rebuilt from Chapters 3 through 7's own files. `before.sh` runs the dynamic inputs through it and saves each output:

```sh
--8<-- "docs/part13/code/before.sh"
```

The inputs (`dyn_add.mlir`, `dyn_transpose.mlir`, `mixed_add.mlir`):

```mlir
--8<-- "docs/part13/code/dyn_add.mlir"
```

```mlir
--8<-- "docs/part13/code/mixed_add.mlir"
```

### What the unmodified compiler did

Parsing and verifying the dynamic add: accepted, as predicted.

```text
--8<-- "docs/part13/code/before/dyn_add_verify.txt"
```

Mixed `?x2` plus `3x2`: **rejected**, which the prediction had missed. The plain `!=` treats `?` and `3` as different, though they can be equal:

```text
--8<-- "docs/part13/code/before/mixed_add_verify.txt"
```

Lowering the dynamic add with Chapter 4/5's pass fails inside the generated IR, as predicted:

```text
--8<-- "docs/part13/code/before/dyn_add_convert.txt"
```

and Chapter 6's One-Shot Bufferize path fails identically:

```text
--8<-- "docs/part13/code/before/dyn_add_bufferize.txt"
```

| Input | Result |
|---|---|
| dynamic add / transpose, parse + verify | accepted |
| `?x2` + `3x2` | **rejected** (verifier too strict) |
| `--convert-mg-to-affine` on dynamic add | `error: 'memref.alloc' op dimension operand count does not equal memref dynamic dimension count` |
| `--one-shot-bufferize` (Chapter 6) | the identical `memref.alloc` error |

So the prediction held for the lowerings, and the verifier was wrong in a way it missed. The lowering failures are **loud**, which is the good kind: the verifier on `memref.alloc` caught what would otherwise have been loops with a `-1` upper bound.

## Step 2: the fix, in one shared header

All three lowering sites (Chapter 5's `AddOpLowering` and `TransposeOpLowering`, Chapter 6's two bufferization models) had the same shape of code, so the fix lives in one new header. In full (`DynamicShapes.h`):

```cpp
--8<-- "docs/part13/code/DynamicShapes.h"
```

What each helper does:

- `compatibleDim(a, b)`: two extents are compatible if equal, **or if either is `?`**.
- `extentOf(...)`: a real `memref.dim`, reading a buffer's runtime size along one dimension.
- `allocFor(...)`: `memref.alloc` with a size operand for each dynamic dimension of the result.
- `nest2D(...)`: the loop nest. **A fully static shape takes exactly the old constant-bound call**, so every earlier chapter's output is unchanged; a shape with a `?` takes the operand-bound path, reading each bound from the extents.

For `mg.add` the result's dynamic extents come from the left operand; for `mg.transpose` the result's extent along dimension *d* is the input's extent along *1 − d*. The verifiers now use `compatibleDim` (and check rank first):

```cpp
--8<-- "docs/part13/code/MgDialect.cpp:46:76"
```

The complete change against Chapters 3, 5 and 6, all 160 lines, so nothing is hidden:

```diff
--8<-- "docs/part13/code/chapter13.diff"
```

The result for a dynamic add (the real output, from the test run below):

```mlir
--8<-- "docs/part13/code/run_out.txt:14:33"
```

Real `memref.dim` reads, a dynamic `memref.alloc(%dim, %dim_0)`, and loops bounded by those values.

## Step 3: two more bugs that dynamic shapes exposed

Testing edge cases found two problems that neither the static examples nor the prediction anticipated.

### The canonicalizer produced invalid IR

Chapter 3's `SimplifyRedundantTranspose` rewrites `transpose(transpose(x))` to `x` unconditionally. The test program (`tt.mlir`):

```mlir
--8<-- "docs/part13/code/tt.mlir"
```

has `x : tensor<?x2xf64>` but an outer result type of `tensor<?x?xf64>`, so replacing the result with `x` changes the type. Note first what happens on the **unmodified** Chapter 7 build: the program never reaches the canonicalizer, because the old verifier rejects it (`?` against `2` is "not equal"):

```text
--8<-- "docs/part13/code/before/tt_on_chapter7_build.txt"
```

The canonicalizer bug only appears once the verifier has been relaxed but the pattern has not. That state is reproduced exactly by the build with the relaxed verifiers and the pattern's guard removed (Chapter 15's first mutation build):

```text
--8<-- "docs/part13/code/before/tt_without_guard.txt"
```

The rewrite replaced the result with `%arg0`, whose type is `tensor<?x2xf64>`, and the function says it returns `tensor<?x?xf64>`. The fix is conservative: the pattern now fires only when `x`'s type equals the result type exactly. The alternative, inserting a `tensor.cast`, would pull in another dialect.

```cpp
--8<-- "docs/part13/code/MgDialect.cpp:99:121"
```

Check: exact types still fold (`tt2.mlir` reduces to `return %arg0`); mixed types are left alone.

```mlir
--8<-- "docs/part13/code/tt2.mlir"
```

### The verifiers cast unranked tensors without checking

`F64Tensor` also accepts `tensor<*xf64>`, and Chapter 3's verifiers used `llvm::cast<RankedTensorType>`. In a release build (no assertions) that cast checks nothing. The unmodified build printed this for an unranked transpose:

```text
--8<-- "docs/part13/code/before/unranked_verify.txt"
```

which looks sensible, but reading the code shows that was luck, not design: `only supports rank-2 tensors` was produced by reading a rank out of an object that is not a ranked type. Both verifiers now use `dyn_cast` and emit an explicit `only supports ranked tensors` (visible in the verifier code above).

## Step 4: run it for real, on non-square shapes

The dynamic program, with both functions in one file (`both.mlir`):

```mlir
--8<-- "docs/part13/code/both.mlir"
```

It went through **both** lowering paths to native code: Chapter 4/5's `--convert-mg-to-affine`, and Chapter 6's `--one-shot-bufferize="bufferize-function-boundaries"`, each followed by the same five-pass lowering, `mlir-translate-18` and `clang-18`, linked with a C harness. The harness fills the rank-2 memref descriptor Chapter 8 introduced, but with sizes chosen at runtime:

```c
--8<-- "docs/part13/code/harness_dyn.c"
```

The scripts that build the compiler and run every check:

```sh
--8<-- "docs/part13/code/build.sh"
```

```sh
--8<-- "docs/part13/code/run_tests.sh"
```

### The complete real output

```text
--8<-- "docs/part13/code/run_out.txt"
```

Reading the sections: 1 shows the mixed add now verifies; 2 shows the explicit unranked diagnostics; 3 shows the canonicalizer leaving mixed types alone and folding exact ones; 4 is the regression check, **byte-identical** to Chapter 10's stored static output (`cmp` reports no difference); 5 is the dynamic add's lowering; 6 and 7 are the native runs. **One compiled function handled five different shapes** (2x3, 3x2 and 1x6 adds; 2x3 and 1x6 transposes), which is the point of dynamic shapes, and a transposed result had a different shape from its input at runtime. Path A and Path B print identical, correct output.

### The strided-view test: where the two paths really differ

Chapter 6 noted that bufferization's function arguments are *strided* memrefs (`memref<?x?xf64, strided<[?, ?], offset: ?>>`) while Chapter 4's are plain row-major; here that difference becomes observable. Section 7 above ends with Path B being called with the same six numbers described as a **column-major** 2x3 matrix (strides `(1, 2)`), whose logical value is `[[1,3,5],[2,4,6]]`:

```text
--8<-- "docs/part13/code/run_out.txt:77:80"
```

That is the correct transpose of the logical matrix. Path A cannot be given this test fairly: its argument type is `memref<?x?xf64>` with the default row-major layout, so a caller passing different strides would be violating that type's contract. The finding is not that A is wrong; it is that **B's types carry strides and A's do not**, a real capability difference that static 2x2 examples could never show.

### Static regression

`--convert-mg-to-affine` on Chapter 10's static `add_tensors.mlir` is byte-identical to Chapter 10's stored `add_affine.mlir`. Chapter 8's static `add_tensors` run natively through both paths with Chapter 8's own harness still prints `[[6, 8], [10, 12]]`, and Chapter 3's canonicalize demo still folds to the same two-operation program.

## What is still not safe

**Runtime shape mismatch is silent memory corruption.** *(Update, added after Chapter 14: closed for `mg.add`. The dynamic add now aborts on a runtime mismatch instead of reading out of bounds; see Chapter 14. The description below is the state when this chapter was written.)* The verifier can only compare shapes it knows at compile time. Called through the dynamic function with `a` as 2x3 and `b` as 1x2 (a buffer holding two doubles):

```c
--8<-- "docs/part13/code/harness_mismatch.c"
```

the add runs to completion and returns garbage (the last line of the real output above):

```text
--8<-- "docs/part13/code/run_out.txt:81:82"
```

The loop bounds come from `a`; the loads from `b` run off the end of its two-element buffer and read whatever sits beyond it. There is no runtime check. The first two values are right (the first two elements exist in both) and `4 5 7 9` is not meaningful, and **the values after the first two are not guaranteed to be reproducible**: they are whatever happened to be in memory (they came out identical across the two runs made for this chapter, which proves nothing about other builds or machines). This is an out-of-bounds read, so it is undefined behavior, and a different run or build could crash instead. Closing it means emitting a runtime comparison of the operands' `memref.dim`s and aborting on mismatch (e.g. a `cf.assert`); this chapter did not do that, because it also needs to confirm the `cf` lowering is present in the five-pass pipeline, and that is a separate piece of verified work. Mountain Goat is **not memory safe** for dynamic shapes until then.

Also still open:

- **Only rank 2.** The verifiers and loops are hard-wired to two dimensions; a rank-3 tensor is rejected by the verifier, which is correct but means dynamic *rank* is out of scope.
- **`mg.constant` stays static.** A literal's shape is always known, so this is by design, not a gap.
- **Chapter 7's loop transforms and Chapters 10 through 12's GPU path were not re-run on dynamic shapes.** *(Update, added after Chapter 17: the loop transforms now have been; see Chapter 17. The GPU path has not.)* Fusion, tiling and unrolling with a `?` bound are untested; full unrolling in particular cannot work without a constant trip count. The GPU path's `bare-ptr` option requires static shapes (Chapter 12), so dynamic-shape GPU lowering was not attempted.
- **No automated tests.** *(Update, added after Chapter 15: now a `lit`/`FileCheck` suite; see Chapter 15.)* `code/run_tests.sh` is a script that prints results for a human to read, not an assertion-based suite.

## Reproducing this chapter

```bash
cd docs/part13/code
./build.sh        # assembles the tree from the earlier chapters' files plus this chapter's four, builds ./build/mg-opt
./run_tests.sh    # runs every check above; output matches run_out.txt
./before.sh       # the unmodified compiler's real outputs (needs ../../part15/code/older_builds.sh and mutation.sh run once)
```

Both `build.sh` and `run_tests.sh` were run from this state after the build directories were removed, and `run_out.txt` is their unedited output; `build/`, `tree/` and `work/` are git-ignored. Needs `mlir-18-tools`, `libmlir-18-dev`, `llvm-18-dev`, `cmake`, `clang-18`. Every file and output above is embedded from the repository when the site is built, so this page cannot drift from the code it describes. As in Chapters 10 through 12, no documentation pages were consulted; every claim comes from running the code or reading it.

## Chapter summary

This chapter turned Chapter 12's biggest unknown, dynamic shapes, into measured facts. Run on an unmodified compiler, `tensor<?x?xf64>` parsed, but a mixed `?x2` plus `3x2` add was wrongly rejected and both lowering paths (the hand-written conversion and One-Shot Bufferize) failed on a dynamic `memref.alloc` with no size operands. One shared header (`DynamicShapes.h`) fixed all three lowering sites, reading runtime extents with `memref.dim`, allocating dynamically and bounding loops by operands, while leaving static programs on their old path (byte-identical to Chapter 10's stored output). The work exposed two more bugs: the transpose-of-transpose canonicalizer produced invalid IR on mixed dynamic types (now guarded), and the verifiers cast unranked tensors without checking (now `dyn_cast` with a diagnostic). Native runs of non-square shapes on both paths were correct, and a column-major strided view only the bufferization path could honor showed a real difference between the two.

Deliberately out of scope, stated explicitly: runtime shape agreement was not checked (closed for `mg.add` in Chapter 14), only rank 2 is supported, and loop transforms and the GPU path were not re-run on dynamic bounds.

## Self-check questions

**1. Why can the lowering not simply use `tensorType.getShape()[0]` as a loop bound when the dimension is `?`?**

Worked answer: for a dynamic dimension `getShape()` returns MLIR's sentinel for "dynamic", `-1`, not a size, so the number would become a bogus loop bound. A dynamic extent has to be read at runtime, with a `memref.dim` operation on the buffer, and passed to the loop and to `memref.alloc` as an operand. The unmodified compiler never got as far as running such a loop: the verifier on `memref.alloc` rejected an allocation of a `memref<?x?xf64>` with no size operands.

**2. `tensor<?x2xf64>` plus `tensor<3x2xf64>` was rejected by the original verifier. Why is rejecting it wrong, and what rule replaced it?**

Worked answer: the `?` may be 3 at runtime, so the two shapes can agree, and a compile-time error would reject a valid program. The original check compared shapes with `!=`, which treats `?` and `3` as different. `compatibleDim(a, b)` now accepts two extents if they are equal or if either is dynamic; the verifier applies it to every dimension of both operands and the result.

**3. The canonicalizer bug did not appear when the program was run on the unmodified compiler. Why not, and how was it reproduced?**

Worked answer: on the unmodified build the mixed-type transpose program was rejected earlier, by the old verifier (`?` against `2` counted as unequal), so the canonicalizer never saw it. The bug only appears once the verifier has been relaxed but the pattern has not been guarded, a state reproduced exactly by the build with the relaxed verifiers and the exact-type guard removed, which printed that the function returns `tensor<?x2xf64>` but is declared to return `tensor<?x?xf64>`.

**4. What does the column-major strided-view test show about the two lowering paths?**

Worked answer: the bufferization path's function arguments are strided memref types (`strided<[?, ?], offset: ?>`), so it honors a caller's strides, and it produced the correct transpose of the logical matrix `[[1,3,5],[2,4,6]]`. The hand-written path's arguments are plain row-major memrefs, so passing different strides would violate its type's contract; the test is not run against it and the chapter says that is not a defect of that path. The finding is a capability difference that static 2x2 examples could not show.

**5. Why did the mismatched-size call (2x3 plus 1x2) return numbers instead of failing?**

Worked answer: the loop bounds come from the first operand and nothing compares the operands' runtime sizes, so the loads from the second operand run off the end of its two-element buffer and read whatever memory is there. The first two sums are right because those elements exist in both; the rest are meaningless and not guaranteed to be reproducible. That silent out-of-bounds read is what Chapter 14 closes with a runtime check.
