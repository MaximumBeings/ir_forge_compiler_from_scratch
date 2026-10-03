# 27. Tensor Contractions as Matrix Products

![Mountain goats in space helmets on Mercury](../assets/goats/ch-27.svg){ style="display:block;margin:0 auto;max-width:100%;height:auto;border-radius:6px" }

**What you will understand:** what a tensor contraction is, why every contraction is "a matrix multiply in disguise", and how to take the disguise off: rearrange the axes of two tensors of any rank so that the entire contraction becomes a single matrix product, which is the one operation Mountain Goat is built around. The matrix product is Mountain Goat's compiled `@`; the axis bookkeeping around it is C++. The result is compared, bit for bit, with the definition of a contraction written out directly, on the worked examples of the *Tensor Contractions (CPU)* appendix of the companion book *CUDA From First Principles*, plus seven more cases.

**What you need to know first:** Chapter 21 (`@`, the matrix product), Chapter 20 (calling compiled Mountain Goat from C++), Chapter 24 (the loop-order option) and, for the final comparison, Chapter 14 (the run-time inner-dimension check). The appendix is not required; its ideas are explained here, and the page links to it.

!!! tip "Compile and run"
    ```sh
    cd docs/part24/code && ./build.sh                  # once: the newest compiler (Chapter 24's mg-opt)
    cd ../../part27/code
    cpp/run.sh                                         # compile contract.mg, build the C++ demo against it, run it (-> cpp/run_out.txt)
    ./contraction_mutation.sh > contraction_mutation_out.txt   # breaks the code on purpose, nine ways
    cd ../../part15/code && ./run_lit.sh               # the whole test suite
    ```
    Every listing and output on this page comes from these commands.

!!! note "Why this page shows FAIL lines, and why that is good"
    The mutation output near the end comes from a **negative control**: the contraction code deliberately broken and run against the tests. There a "caught" line (a test failed) is the expected, wanted result. The baseline line must say the tests pass, and it does. The `trap skip` output in the middle of the page is also meant to abort: that is the check working.

## Where this comes from

*CUDA From First Principles* (a companion book by the same author) has an appendix, [Tensor Contractions, From First Principles (CPU)](https://maximumbeings.github.io/cuda-from-first-principles/appendix/tensor-contractions-cpu/) (source: `docs/appendix/tensor-contractions-cpu.md` in the `MaximumBeings/cuda-from-first-principles` repository), which defines a contraction, implements a generic N-dimensional `contract()` in C++ with nested index loops, verifies it against `numpy.tensordot`, shows what goes wrong without an axis check, and measures loop order. Its opening line is the idea of this chapter: *"Every tensor contraction you will ever write is either a matrix multiply in disguise, or a small collection of matrix multiplies stapled together."*

Mountain Goat is a language about two-dimensional matrices, so this chapter takes that sentence literally. It reimplements the appendix's definition (as an independent checker, written fresh for this chapter) and then does the contraction the other way, through a matrix product, which is how libraries do it. The appendix's two worked examples and its axis-mismatch case are reproduced exactly. (The environment this book is written in could not open the appendix's web page, so everything above comes from reading its source in the repository, at commit `6b3f95f`.)

## Primer: a contraction is a matrix product in disguise

A **tensor** is a block of numbers with some number of axes, each with a size: a vector has one axis, a matrix two, and a `[2, 3, 4]` tensor three. A **contraction** takes two tensors, pairs up some axes of the first with some axes of the second (the paired axes must have the same size), and for every combination of the *other* ("free") axes sums the products of matching elements over every value of the paired axes. The paired axes disappear from the result; the free axes remain, first A's and then B's.

The matrix product is the simplest case: `C[i][j] = Σ_k A[i][k] · B[k][j]` pairs A's axis 1 with B's axis 0. The disguise comes off with one observation. Group A's axes into two bundles, the **free** ones and the **contracted** ones, and think of each bundle as a single combined axis (a row number counting all combinations of the free axes, a column number counting all combinations of the contracted ones). Then A is just a matrix `[M, K]`, where `M` is the product of A's free sizes and `K` is the product of the contracted sizes. Do the same for B with the contracted bundle first: a matrix `[K, N]`. The contraction is then exactly `C[m][n] = Σ_k A'[m][k] · B'[k][n]`: a matrix product. Reshape `C` back to A's free sizes followed by B's free sizes and you have the answer.

The recipe is called **transpose-reshape-GEMM-reshape** (GEMM is the traditional name for a general matrix multiply). Each word is a step:

1. **Transpose** (more exactly, *permute*): reorder A's axes so the free ones come first and the contracted ones last; reorder B's so the contracted ones come first and the free ones last. The contracted axes must be listed in the same pairing order for both. This step copies data, unless the axes are already in that order.
2. **Reshape**: a tensor stored row-major (last axis fastest) is already a flat buffer; viewing it as a matrix with `M` rows and `K` columns needs no copying at all, only a different way of reading the same numbers.
3. **GEMM**: one matrix product `[M, K] · [K, N]`. This is where all the arithmetic is, and in this chapter it is one compiled Mountain Goat function.
4. **Reshape** the `[M, N]` result back to the output shape (again, no copying).

**A worked example.** Contract A of shape `[2, 3, 4]` with B of shape `[3, 4, 5]`, pairing A's axes `{1, 2}` with B's `{0, 1}`. A's free axis is `{0}` (size 2) and its contracted axes are sizes 3 and 4, so `M = 2` and `K = 3·4 = 12`; B's contracted axes are already first (sizes 3 and 4) and its free axis has size 5, so `N = 5`. Nothing needs permuting: A is read as a `2×12` matrix and B as a `12×5` matrix, one product gives `2×5`, which is the output shape. The multiply-add count is `M·N·K = 2·5·12 = 120`, which is the appendix's formula (output elements times the product of contracted sizes: `10 · 12`).

**Degenerate cases fall out for free.** With *no* contracted axes the empty product gives `K = 1`: a `[M, 1]` times a `[1, N]` is the **outer product**. With *every* axis contracted, `M = N = 1`: a `[1, K]` times a `[K, 1]` is the **dot product**, a `1×1` matrix, which is the scalar (a tensor of rank 0, the empty shape `[]`).

## The Mountain Goat part

All of the arithmetic is this:

```text
--8<-- "docs/part27/code/cpp/contract.mg"
```

One function, `gemm`: a matrix product with dynamic row and column counts, so a single compiled function serves every contraction whatever its shape. (Mountain Goat has no tensors of rank 3 or more; that is why the reshaping lives in C++.) It is built with `-O2` and the `ikj` loop order from Chapter 24.

## The C++ part: the definition, and the matrix-product version

```cpp
--8<-- "docs/part27/code/cpp/tensor.h"
```

Two functions with the same signature. **`contract_reference`** is the definition, written directly: for each output index, add up `A·B` over every combination of the contracted indices, with no matrix product anywhere. It exists only to check the other. **`contract_ttgt`** is the recipe: it works out the free and contracted axes, builds the two permutations (`perm_a` is the free axes followed by the contracted ones, `perm_b` the contracted ones followed by the free ones), calls `permute` (the only step that moves data), wraps each result as an `mg::Matrix` whose sizes are the products of the bundled axes, calls `mg::gemm`, and reads the product back as a tensor of the output shape. `validate` checks the axis lists before anything else: equal length, every axis in range and not repeated, and every contracted pair the same size.

The demo program runs the cases and prints, for each, whether the two versions agree bit for bit:

```cpp
--8<-- "docs/part27/code/cpp/contract_demo.cpp"
```

## The run

```sh
--8<-- "docs/part27/code/cpp/run.sh"
```

```text
--8<-- "docs/part27/code/cpp/run_out.txt"
```

**Reading it.**

- **Cases 1 and 2** are the appendix's worked examples. The matrix product `[3,2]·[2,4]` gives the values the appendix checked against numpy's `@`. The double contraction `[2,3,4] × [3,4,5]` over two axis pairs gives `[[10, 5, 0, −5, −10], [2, 1, 0, −1, −2]]`, the values the appendix checked against `numpy.tensordot`. Neither check here uses numpy: the expected values come from the appendix's page, and the independent check is the definition.
- **Case 3** is nine contractions chosen to exercise the bookkeeping: a contracted axis at the *front* of A (which forces a real permutation), contracted axes listed in *reverse* order (so the pairing order matters), contracted axes in the middle of both tensors, a vector times a matrix, a dot product (the `[]` shape: a scalar), an outer product (no contracted axes), and rank-3 times rank-3 giving a rank-4 result. For all nine the matrix-product version equals the definition **bit for bit**, on numbers that are deliberately not "nice" (they are not exactly representable, so a different order of additions would change the last bits). That is expected for a reason worth stating: the flattened contracted index runs through the contracted axes in the same row-major order the definition uses, so each output element adds its products in the same order.
- **Case 4** is the appendix's section H.5, with extra axis mistakes: a mismatched pair (`A.shape[1]=2` against `B.shape[0]=4`), lists of different lengths, an out-of-range axis, and a repeated axis. Each is rejected with a specific message. (The mismatch message uses the appendix's wording, so the two outputs line up.)

## The trap, revisited: what happens if the check is skipped?

The appendix demonstrates why the axis check matters. An unchecked contraction, given the same mismatched `[3,2]` and `[4,5]`, "does not crash and does not fail loudly: it silently sizes the contracted-index loop from `A`'s axis alone (size 2) and reads only the first 2 of `B`'s 4 rows", producing a plausible, wrong `3×5` result (that experiment is the appendix's, not reproduced here). The two `trap` runs above show the Mountain Goat version of the same experiment. With the check **on**, the mismatch is an exception with a precise message. With the check **skipped** (`trap skip`), the two tensors are flattened to a `3×2` and a `4×5` matrix and handed to `gemm`, and Mountain Goat's own run-time shape check (Chapter 14) stops the program: `mg.matmul: inner dimensions differ at runtime` on stderr, exit status 134, and nothing printed after it. So here the failure is not silent even if the C++ validation is deleted: the compiled matrix product refuses to multiply matrices whose inner sizes disagree, which is precisely the protection the appendix had to add by hand.

## Loop order, again

The appendix's last section measures how the loop order of a matrix multiply changes its running time without changing its answer, on a plain C++ triple loop (`ijk` against `ikj`). That is the same experiment as Chapters 23 and 24, which ran it on Mountain Goat's own compiled `@` and found the same effect (`ikj` several times faster at larger sizes on this machine, with identical results), and added `--matmul-order ikj` so the faster order can be chosen. A contraction done through `gemm` inherits that: the `contract.mg` here is built with `ikj`, and the test builds it both ways and requires identical output. No new timing is claimed in this chapter; the numbers in Chapters 23 and 24 apply to square products on one shared machine, not to these small demonstration shapes.

## Tests

Two new `lit` tests in `test/contraction/` (the suite now has 105 tests):

| Test | What it checks |
|---|---|
| `tensor-contraction` | the demo, built **twice** (optimized with `ikj`, and with the plain defaults), must print every expected value and `yes`, with identical complete output from both builds; checks the appendix's two worked results, the `2x12` times `12x5` reshape line, all nine cases, and the exact message of each axis check |
| `mismatch-trap` | with the check on, the exception message; with the check skipped, an abort with Mountain Goat's message on stderr and nothing after the "SKIPPED" line |

### Are the tests good enough? Break the code nine ways.

`contraction_mutation.sh` damages `tensor.h` or `contract.mg` one way at a time and re-runs the two tests:

```sh
--8<-- "docs/part27/code/contraction_mutation.sh"
```

```text
--8<-- "docs/part27/code/contraction_mutation_out.txt"
```

All nine are caught, including the four that are about the *axis bookkeeping* (swapping which axes come first, taking B's contracted axes in sorted order instead of paired order, listing B's free axes first in the output), the three about *validation* (the size check, repeated axes, out-of-range axes), and the two about the *Mountain Goat function itself*. Two details are worth noticing. The mutation "B's contracted axes taken in increasing order, not paired" is caught only because case 3 includes a contraction with axes listed in reverse order; on the simpler cases, where axes are already in increasing order, it changes nothing. And the validation mutations are caught by looking at the **exact message**: a repeated axis, for example, would otherwise be rejected anyway by the size check further down (with a different message), so a test that only asked "was it rejected?" would not notice that the repeated-axis check had been removed.

The full suite:

```text
--8<-- "docs/part15/code/run_out_105.txt"
```

## Limits and what is not established

- **Rank-2 arithmetic only.** Mountain Goat has no tensors of rank 3 or more, so the permuting and reshaping are C++. Only the matrix product is the language's. A language-level reshape and permute are not built here; [Chapter 28](../part28/28-contraction-in-mountain-goat.md) builds them, and writes the same contractions with no C++.
- **The permutation copies.** When the axes are not already in the needed order (case 3, "axis at the front of A"), `permute` copies the whole tensor before the product. That cost was **not measured**, and a production library would avoid or fuse it. When the axes already line up (the appendix's double contraction), no data moves.
- **No batch axes.** A contraction pairs axes and sums them away; operations like batched matrix multiply (an axis present in both inputs *and* the output) are `einsum`, not a contraction in this sense, and are not supported.
- **Small shapes only were tested,** all `double`, all tiny (the largest has a few hundred elements). Nothing here says how it behaves on large tensors, and nothing was timed.
- **The reference is mine, not the appendix's code.** `contract_reference` was written for this chapter; it agrees with the appendix's printed values (cases 1 and 2) and with the matrix-product version on all nine cases, but the appendix's own program was not run here.
- **Bit-for-bit equality is shown for these cases on this build.** It follows from the order of additions being the same, which is an argument plus nine tests, not a proof for every shape; a different compiler setting that reorders floating-point additions (for example, fast-math flags, which this build does not use) would break it.
- **The GPU side is not covered.** The appendix has a companion for CUDA; Mountain Goat's GPU path is compile-only (Chapters 10 to 12) and nothing here runs on a GPU.
- **Platform:** x86-64 Linux, LLVM 18.1.3.

## Reproducing

```sh
cd docs/part24/code && ./build.sh
cd ../../part27/code
cpp/run.sh > cpp/run_out.txt 2>&1
./contraction_mutation.sh > contraction_mutation_out.txt
cd ../../part15/code && ./run_lit.sh          # 105 tests
```

## Chapter summary

- A contraction pairs axes of two tensors and sums products over them. Bundling each tensor's free axes into one axis and its contracted axes into another turns it into an ordinary matrix product: **permute, reshape, multiply, reshape**.
- With Mountain Goat that gives a one-line function, `gemm`, for all the arithmetic; the C++ around it only rearranges axes.
- It agrees bit for bit with a direct implementation of the definition on the appendix's two worked examples and nine further cases, including a front-of-A axis, reversed axis order, a dot product (rank 0), an outer product, and a rank-4 result.
- Skipping the axis check does not silently corrupt the result: Mountain Goat's run-time inner-dimension check aborts with a message, where an unchecked hand-written loop (as the appendix shows) quietly drops half of one input.
- The loop-order effect the appendix measures is the same one Chapters 23 and 24 measured and made selectable.
- Nine injected bugs are all caught; two of them are caught only because the cases were chosen to exercise reversed axis order and exact error messages.

## Self-check questions

Each answer is collapsed; try the question first.

1. In one sentence each, what are free axes and contracted axes, and what does the output shape consist of?

    ??? note "Answer"
        Contracted axes are the paired axes that are summed over and disappear; free axes are all the others and survive. The output shape is A's free axes followed by B's free axes, each at its original size.

2. A has shape `[2,3,4]` and B has shape `[3,4,5]`; the pairs are A's axes `{1,2}` with B's `{0,1}`. What matrices does the matrix-product version multiply, and how many multiply-adds does that take?

    ??? note "Answer"
        A is read as `[2, 12]` (the free axis, then the two contracted axes bundled: 3·4 = 12) and B as `[12, 5]` (the contracted axes bundled, then the free axis). The product is `[2, 5]` and takes 2·5·12 = 120 multiply-adds, equal to the appendix's formula: output elements (10) times the product of the contracted sizes (12).

3. Why does the "reshape" step cost nothing in this case, and when does the "transpose" step have to copy data?

    ??? note "Answer"
        A row-major tensor is already a flat buffer, so viewing it as a matrix just changes how the same numbers are read. Here A's free axis is first and its contracted axes are last, and B's contracted axes are first and its free axis last, so no reordering is needed. If an axis is somewhere else (say, a contracted axis at the front of A), the axes must be reordered, which means copying the data into the new order.

4. What are the matrix shapes for an outer product (no contracted axes) and for a dot product (all axes contracted), and why?

    ??? note "Answer"
        An outer product has K = 1, because the product of no sizes is 1: a `[M, 1]` times a `[1, N]` gives `[M, N]`. A dot product has no free axes, so M = N = 1 (again the empty product): a `[1, K]` times a `[K, 1]` gives `[1, 1]`, the scalar, which the tensor code represents with the empty shape.

5. Why does case 3 include a contraction with the contracted axes listed in reverse order, and what mutation does it catch?

    ??? note "Answer"
        The pairing order of the contracted axes matters: the axis listed first for A must meet the axis listed first for B. If B's contracted axes were instead taken in sorted order, simple cases where the axes are already increasing would still be right, and only a case with a reversed order would produce wrong numbers. The mutation "B's contracted axes taken in increasing order, not paired" is caught by exactly that case.

6. Why are the results bit-for-bit identical to the definition rather than merely close?

    ??? note "Answer"
        For each output element both versions add the products in the same order: the flattened contracted index runs over the contracted axes in row-major order, the same order the direct definition's inner loop uses. Floating-point addition is not associative, but the same sequence of additions gives the same bits. The test uses numbers that are not exactly representable so that a different order would show.

7. What happens if the axis validation is skipped and the contracted sizes differ, in the appendix's unchecked version and here?

    ??? note "Answer"
        In the appendix's unchecked version the loop is sized from one tensor's axis and quietly reads only part of the other tensor, giving a plausible but wrong result with no error. Here the two tensors are flattened to matrices with different inner sizes and handed to the compiled matrix product, whose own run-time check (Chapter 14) aborts with `mg.matmul: inner dimensions differ at runtime`. The failure is loud even without the C++ validation.

8. Why does the mutation script check the exact error message rather than only that an exception was thrown?

    ??? note "Answer"
        Several mistakes are caught by more than one check. If the repeated-axis check were deleted, a later check (the size comparison) might still throw for the same input, with a different message; a test that only asked "was an exception thrown?" would pass, and the deleted check would go unnoticed. Checking the exact message distinguishes which check fired.

9. Why can't this chapter claim anything about the speed of contractions?

    ??? note "Answer"
        Nothing was timed: the shapes are tiny and meant for checking correctness, and the permutation's copy cost was not measured. Chapters 23 and 24 measured square matrix products on one shared machine, and those numbers cannot be transferred to other shapes or to the permute-and-reshape overhead.

10. What would be needed for Mountain Goat itself, not C++, to express a general contraction?

    ??? note "Answer"
        Tensors of rank greater than two, a reshape operation (a no-copy reinterpretation of a contiguous tensor as another shape) and a general permute (a transpose over any axes), each with a verifier, a lowering and front-end syntax and tests, as in Chapters 21 and 22. Alternatively a single contraction operation with axis-list attributes, lowered to the same permute, reshape and matrix product. The C++ code in this chapter is a specification of what those operations would have to do.
