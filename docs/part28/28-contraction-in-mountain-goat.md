# 28. Tensor Contractions in Mountain Goat Itself

**What you will understand:** how Mountain Goat gets tensors of rank 3 and more, and how a general tensor contraction becomes a short Mountain Goat program with **no C++ in it**. Chapter 27 did the axis bookkeeping (permuting and reshaping) in C++ and left only the matrix product to the language; its "Limits" section said a language-level reshape and permute were not built. This chapter builds them: two new compiler operations, `mg.reshape` and `mg.permute`, and three new built-ins, `reshape`, `permute` and `contract`. Everything is checked against the *definition* of a contraction (plain nested loops, no matrix product) on thirteen shape combinations, and against the worked examples of the *Tensor Contractions (CPU)* appendix of the companion book *CUDA From First Principles*.

**What you need to know first:** Chapter 27 (what a contraction is and why it is a matrix product in disguise: read its primer first), Chapter 22 (how an operation is added to the dialect, the lowering and the front end) and the language tour.

!!! tip "Compile and run"
    ```sh
    cd docs/part28/code && ./build.sh                 # once: the newest compiler (adds mg.reshape and mg.permute)
    ./mgc run examples/03_double_contraction.mg       # compile and run one example
    ./mgc mlir examples/04_axis_at_the_front.mg       # show the MLIR the front end produces
    ./run_examples.sh > examples_out.txt              # every example and every error example on this page
    ./check_contractions.py                           # 13 shape combinations against the definition, exact
    ./mutation.sh > mutation_out.txt                  # breaks the compiler on purpose, 21 ways (about ten minutes)
    cd ../../part15/code && ./run_lit.sh              # the whole test suite
    ```
    Every listing and output on this page comes from these commands.

!!! note "Why this page shows FAIL lines, and why that is good"
    Two places show failures on purpose. The **error examples** are programs the compiler must reject: each ends with `exit status 1` and produces no program. The **mutation output** comes from a negative control: the compiler deliberately broken and run against the tests, where a "caught" line (a test failed) is the wanted result and "NOT CAUGHT" would be a test gap.

## What was missing

Until now every Mountain Goat value was a two-dimensional matrix. Chapter 27's recipe, *permute, reshape, multiply, reshape*, needs tensors of any rank and the two rearranging steps. Chapter 27 kept those in C++ and noted that the language itself could do them with three additions: tensors of rank greater than two, a reshape, and a permute. Here they are.

## The three new built-ins

| Written | Meaning | Checked at compile time |
|---|---|---|
| `reshape(x, d0, d1, ...)` | the same numbers, viewed with shape `d0 x d1 x ...` (row-major order; no data moves) | `x` has a static shape; the element counts are equal |
| `permute(x, p0, p1, ...)` | reorder the axes: result axis `i` is input axis `pi` | `p` lists each axis exactly once |
| `contract(a, (i, j, ...), b, (k, l, ...))` | sum the products over the paired axes: `a`'s axis `i` with `b`'s axis `k`, and so on | both lists the same length; every axis in range and not repeated; every pair the same size |

Literals stay matrices, so a rank-3 value is made by reshaping one: `reshape([[1, 2, ..., 12], [13, ..., 24]], 2, 3, 4)` is a `2x3x4` tensor whose first block is the numbers 1 to 12. Only five things can be done with a value of rank other than 2: `reshape` it, `permute` it, `contract` it, bind it with `let`, or `print` it. Arithmetic, `transpose`, reductions and function arguments need a matrix, and say so (see error 7).

## One by one

### 1. Reshape and permute

```text
--8<-- "docs/part28/code/examples_out.txt:1:40"
```

The first `print` shows the `2x3x4` tensor: two blocks of three rows of four. `permute(a, 1, 0, 2)` swaps the first two axes: result axis 0 is input axis 1, so the shape becomes `3x2x4`, and the first result block holds row 0 of each original block (`1 2 3 4` and `13 14 15 16`). `permute(a, 2, 0, 1)` is a rotation of the axes (a *3-cycle*): the shape `2x3x4` becomes `4x2x3`. This example is worth keeping in mind because a swap undone is the same swap, but a 3-cycle is not: reading the permutation backwards gives a different tensor, and the tests below depend on that. The last line reshapes the same 24 numbers into a `4x6` matrix; it copies nothing.

### 2. A matrix product is a contraction

```text
--8<-- "docs/part28/code/examples_out.txt:42:57"
```

`contract(a, (1), b, (0))` sums over `a`'s axis 1 against `b`'s axis 0, and gives exactly `a @ b`. These are the appendix's numbers (its first worked example). The compiler produces **no reshape and no permute** for it: one `mg.matmul` (a test asserts that).

### 3. The appendix's double contraction

```text
--8<-- "docs/part28/code/examples_out.txt:59:70"
```

`A` is `2x3x4` with `A[i] = (i % 7) - 3`, `B` is `3x4x5` with `B[i] = (i % 5) - 2`, both numbered in row-major order. Pairing A's axes `{1, 2}` with B's `{0, 1}` leaves A's axis 0 and B's axis 2: a `2x5` result, and it is the appendix's `numpy.tensordot` answer, `[[10, 5, 0, -5, -10], [2, 1, 0, -1, -2]]`. (The literals in this file were generated by `examples/gen_big_literals.py`, which is checked in.)

### 4. A contracted axis at the front

```text
--8<-- "docs/part28/code/examples_out.txt:72:92"
```

Here A's contracted axis is its **first** axis, so A cannot simply be read as a matrix: it must be permuted first. This is the one case in the family where the language moves data. The MLIR the front end writes shows the four steps (this is what `mgc mlir` prints, comments removed):

```text
%t4 = mg.permute %t2 {permutation = array<i64: 1, 2, 0>} : tensor<2x3x4xf64> -> tensor<3x4x2xf64>
%t5 = mg.reshape %t4 : tensor<3x4x2xf64> -> tensor<12x2xf64>
%t6 = mg.matmul %t5, %t3 : tensor<12x2xf64>, tensor<2x5xf64> -> tensor<12x5xf64>
%t7 = mg.reshape %t6 : tensor<12x5xf64> -> tensor<3x4x5xf64>
```

Permute A so the free axes `(1, 2)` come first and the contracted axis `0` last, view the result as a `12x2` matrix, multiply by B (already a `2x5` matrix), view the `12x5` product as `3x4x5`. That is Chapter 27's recipe, written by the compiler instead of by hand.

### 5. Axes in reverse order

```text
--8<-- "docs/part28/code/examples_out.txt:94:104"
```

The order in which the pairs are listed matters: the first axis listed for A meets the first listed for B. Here `(2, 1)` against `(0, 1)` pairs A's axis 2 (size 4) with B's axis 0 (size 4) and A's axis 1 (size 3) with B's axis 1 (size 3). Listing them as `(1, 2)` against `(0, 1)` would pair sizes 3 and 4 with 4 and 3 and be an error.

### 6. Vectors: dot product, outer product, vector times matrix

```text
--8<-- "docs/part28/code/examples_out.txt:106:122"
```

A rank-1 tensor is made by reshaping a one-row matrix to a single dimension. Contracting every axis (the dot product) gives the scalar `14`, **returned as a `1x1` matrix** (the language has no rank-0 values). Contracting nothing (the outer product) is a table of products. The third result is a rank-1 vector, which prints with `sizes = [3]`.

### 7. A rank 4 result

```text
--8<-- "docs/part28/code/examples_out.txt:124:139"
```

A is `2x2x3` and B is `3x2x2`; contracting only the 3's leaves A's two free axes and B's two, `2x2x2x2`.

### 8. Inside a function

```text
--8<-- "docs/part28/code/examples_out.txt:141:152"
```

Function parameters are still matrices, so the function reshapes them. The shapes are checked once, when the function is defined, and the compiled function works for any values. The output is `12*(i+1)*(k+1)` at row `i`, column `k` (here `b` repeats `1..5` along its last axis and `a` is all ones in row 0, all twos in row 1, and each output sums 12 products), which you can verify by hand.

## Mistakes the compiler reports

```text
--8<-- "docs/part28/code/examples_out.txt:154:217"
```

In order: a contracted pair of different sizes (the appendix's trap, now caught **when the program is compiled**, before any code exists); axis lists of different lengths; an axis number that does not exist; an axis listed twice; a reshape whose element counts differ; a permutation that repeats one axis and omits another; arithmetic on a rank 3 value (it must be reshaped or contracted first); and `reshape` of a value with a `?` size (the compiler cannot know whether the counts match, so it refuses; a `?` dimension is only ever checked at run time, Chapter 14). Each exits with status 1 and gives the file and line.

Compare with Chapter 27's treatment of the same trap. There, with the check on, C++ threw an exception; with the check skipped, Mountain Goat's run-time inner-dimension check aborted the program. Here, because every size in a contraction is a number in the source, the mismatch is found *before* the program exists. The "unchecked loop that quietly reads half of one input" the appendix warns about cannot be written in this language at all.

## How it works

Three layers, the same three as every earlier operation.

**The dialect (`MgOps.td`, `MgDialect.cpp`).** `mg.reshape` takes a static tensor and returns a static tensor with the same number of elements. `mg.permute` carries a `permutation` attribute. Each has a verifier: reshape rejects unequal element counts and dynamic shapes; permute rejects a permutation that does not list each axis once, a wrong length, and a result shape that is not the input's axes in the new order. `tests/verifiers.mlir` feeds each one bad MLIR directly, so a different front end could not build an invalid operation.

**The lowering (`LowerToAffine.cpp`).** The two operations are lowered very differently, and the difference is the whole performance story:

- `mg.reshape` becomes a `memref.reinterpret_cast`: the same buffer with a new list of sizes and the row-major strides. **No element moves.** This is safe because a Mountain Goat value never changes after it is made.
- `mg.permute` becomes a loop nest with one `affine.for` per axis, running over the *result* and storing into each result element the input element whose axis `perm[k]` has the loop's `k`-th index. This is a real copy of the whole tensor.

**The front end (`mgfront.py`).** `contract` is not a new operation: it is **desugared** into the operations above, in this order. Work out A's free axes `fa` and contracted axes `ia` (as listed), and B's `ib` and `fb`. Permute A to `fa + ia`, reshape it to `M x K` (where `M` is the product of A's free sizes and `K` the product of the contracted sizes). Permute B to `ib + fb` and reshape it to `K x N`. One `mg.matmul`. Reshape the `M x N` product to A's free sizes followed by B's. When a permutation is the identity, or a reshape does not change the shape, the front end emits nothing, so a plain matrix product is just an `mg.matmul` and example 3 contains no `mg.permute`. If every axis is contracted the result is the `1x1` matrix noted above.

## Tests

Six new `lit` files in `test/contraction28/` (the suite is now 111 tests):

| Test | What it checks |
|---|---|
| `examples` | the eight examples print the values on this page |
| `errors` | the eight mistakes give the exact messages shown, with file and line |
| `verifiers` | five bad uses of `mg.reshape`/`mg.permute` as raw MLIR are rejected with the exact diagnostic |
| `ir` | example 4 turns into the four-step MLIR above; example 3 has **no** `mg.permute`; example 2 has no `mg.permute` and no `mg.reshape` |
| `against-definition` | `check_contractions.py`: thirteen shape combinations, whole numbers and quarters, **exactly** equal to a loop-by-loop definition written separately in Python |

The thirteen combinations are the nine Chapter 27 used (matrix product, double contraction, axis in the front of A, axes in reverse order, axes in the middle of both, vector times matrix, dot product, outer product, rank 3 by rank 3 with one shared axis) plus four new ones: a 3-cycle of axes on both sides, scattered contracted axes with their order swapped, a rank-5 operand, and size-1 axes. The numbers are small whole numbers, then multiples of a quarter, which are exact in binary, so "equal" means every digit and no tolerance is involved.

```text
--8<-- "docs/part28/code/check_contractions_out.txt"
```

### Are the tests good enough? Break the compiler 21 ways.

```sh
--8<-- "docs/part28/code/mutation.sh"
```

```text
--8<-- "docs/part28/code/mutation_out.txt"
```

All 21 are caught. Four things are worth noticing.

- **The 3-cycle matters.** "permute reads through the INVERSE permutation" is caught only because examples and cases use permutations that are not their own inverse (the 3-cycle in example 1, and the rotated axes in the reference cases). A swap-only test would have let it through.
- **One mutation is caught by only one test.** "B's contracted axes taken in increasing order, not as paired" changes nothing in any of the eight examples (their axes are already in increasing order for B) and is caught only by `against-definition`, whose cases include axes listed in reverse. That is the same lesson as Chapter 27's, and the reason the comparison with the definition exists.
- **Two mutations change no output, and are still caught.** Emitting an identity `permute` or a same-shape `reshape` copies or views data for nothing, so no *value* test could notice. The `ir` test asserts that example 3 contains no `mg.permute` and that example 2 contains neither operation, which turns "no data moves when none needs to" into something that can fail.
- **The front end and the verifiers guard the same mistakes.** With the front end's reshape or permutation check deleted, the *errors* test still fails (it expects the front end's message), while `verifiers` shows the dialect rejects the bad operation by itself. One of the first runs of this script contained a mutation that did not compile ("BUILD FAILED"), which the script reports rather than hides; it was rewritten and the whole script re-run, and the output above is from that complete run.

## Limits and what is not established

- **Static shapes only.** `reshape`, `permute` and `contract` need every size known when compiling; a `?` size is rejected. The tensors of rank other than 2 cannot be function parameters or results, only intermediate values (a function reshapes its matrix arguments, and a result is a matrix).
- **No arithmetic on rank 3 and up.** Elementwise `+`, `*`, `relu`, reductions and `@` still need matrices. A rank 3 value must be reshaped, or contracted, first. Adding rank-N elementwise operations is straightforward and not done.
- **No scalars of rank 0.** A full contraction (a dot product) returns a `1x1` matrix. A `1x1` matrix is the language's scalar-shaped value; it is not the compile-time number a literal like `2` is.
- **No batch axes.** As in Chapter 27, a contraction pairs axes and sums them away. An axis present in both inputs *and* the output (batched matrix multiply, `einsum`) is not supported. Chapter 29's attention needs batches of one head and avoids the question.
- **The permutation copies.** `permute` is a real copy of the whole tensor, and a contraction like example 4 pays for it. **No timing was done** here, the copy was not fused into the product, and no claim is made about the cost on large tensors. The reshape is free.
- **Only small shapes were run,** all `f64`, the largest a few hundred elements (the rank-5 case has 48 elements in its first operand).
- **Exactness depends on the order of additions,** which the desugaring keeps the same as the definition's (the flattened contracted index runs through the pairs in the order listed). That is why the equality is exact for these cases. It is an argument plus 26 passing runs, not a proof for every shape, and a compiler setting that reorders floating-point additions would break it. The test data are exact in binary, so it would not show that.
- **The language's `contract` is not `einsum`.** No repeated-subscript notation, no diagonals (an axis listed twice is rejected), no trace.
- **The appendix's own program was not run** (see Chapter 27). The agreement shown is with the appendix's printed values and with the definition written for these chapters.
- **GPU:** not covered; the GPU path is compile-only (Chapters 10 to 12) and `mg.reshape`/`mg.permute` have no GPU lowering.
- **Platform:** x86-64 Linux, LLVM 18.1.3.

## Reproducing

```sh
cd docs/part28/code && ./build.sh
./run_examples.sh > examples_out.txt
./check_contractions.py > check_contractions_out.txt
./mutation.sh > mutation_out.txt
cd ../../part15/code && ./run_lit.sh          # 111 tests
```

## Chapter summary

- Mountain Goat now has tensors of any rank, with `reshape`, `permute` and `contract` built in. A contraction is written in the language, with no C++ around it.
- `reshape` is free (a new view of the same buffer); `permute` copies; `contract` is a compile-time rewrite into permute, reshape, **one** matrix product, reshape.
- It agrees exactly with the definition of a contraction on thirteen shape combinations and with the appendix's worked values.
- Mistakes the appendix had to check at run time (a mismatched contracted pair, a repeated axis, an out-of-range axis) are compile errors here.
- The tests are shown able to fail: 21 injected bugs in the front end, the verifiers and the lowering.

## Self-check questions

Each answer is collapsed; try the question first.

1. What is the shape of `contract(a, (0, 2), b, (1, 0))` for `a` of shape `[3, 5, 4]` and `b` of shape `[4, 3, 6]`, and which matrices are multiplied?

    ??? note "Answer"
        A's axis 0 (size 3) pairs with B's axis 1 (size 3), and A's axis 2 (size 4) with B's axis 0 (size 4). A's free axis is axis 1 (size 5); B's is axis 2 (size 6). The output is `[5, 6]`. A is permuted to `[5, 3, 4]` (free axis first, then the contracted axes in the order listed: 0 then 2, i.e. sizes 3 and 4) and read as `5x12`; B is permuted to `[3, 4, 6]` (axis 1, then axis 0, then the free axis 2) and read as `12x6`. The product is `5x6`.

2. Why does example 2's contraction compile to a single `mg.matmul`, while example 4's needs an `mg.permute`?

    ??? note "Answer"
        In example 2, A's free axis is already first and its contracted axis last, and B's contracted axis is already first, so the row-major data of each is already a matrix and nothing needs to move. In example 4, A's contracted axis is first, so its numbers are not in the order a matrix product needs (free axes bundled as rows, contracted as columns), and the data must be copied into that order.

3. Which of `reshape` and `permute` copies data, and why can the other not?

    ??? note "Answer"
        `permute` copies. After permuting, the same logical tensor must be laid out in memory with a different axis order, and this chapter's matrix product reads its operands row-major, so the numbers have to be moved. `reshape` only changes how a flat, row-major buffer is cut into axes, which does not change where any number is stored, so it is a new view of the same memory.

4. Why must a 3-cycle (not a swap) be among the permutation tests?

    ??? note "Answer"
        A swap is its own inverse: applying it forwards or backwards gives the same tensor. A lowering that reads the permutation the wrong way round would therefore pass every swap-only test. A 3-cycle is not its own inverse, so only it exposes that mistake. The mutation "permute reads through the inverse permutation" is caught only because of this.

5. Why is the mismatch of the appendix's trap a compile error here but a run-time abort in Chapter 27?

    ??? note "Answer"
        Chapter 27's C++ built the matrices from sizes known only when the C++ ran, so the sizes reached the compiled matrix product as run-time numbers and only its run-time check could stop them. Here the sizes are literal numbers in the source, so `contract` can compare them while compiling. A `?` size could not be checked at compile time; that is why `reshape` and `contract` refuse values with a `?` dimension.

6. Why does the dot product return `[[14]]` (a `1x1` matrix) rather than `14`?

    ??? note "Answer"
        The language has no rank-0 tensors: a number such as `14` in the source is a compile-time scalar, folded away before code is generated, while a computed value must be a tensor with a shape. The dot product is computed at run time, so it is a `1x1` matrix.

7. What does `reshape(x, 2, 3, 4)` do when `x` is `4x6`, and what is printed?

    ??? note "Answer"
        It views the 24 numbers of `x` in row-major order as two blocks of three rows of four. Nothing is copied. For `x` holding 1 to 24 row by row, the first block is rows `1 2 3 4`, `5 6 7 8`, `9 10 11 12`. (`4x6` and `2x3x4` both have 24 elements; `reshape(x, 4, 2)` would be an error: 6 and 8 elements differ.)

8. The mutation "an unneeded permute is emitted (identity permutation not skipped)" does not change any program's output. Why is it still worth catching?

    ??? note "Answer"
        An identity permute is a full copy of a tensor for nothing: it would slow every contraction down without changing its answer, and no test of *values* could ever notice. The `ir` test asserts that example 3 has no `mg.permute` at all, which is how a performance property (no data moves when none needs to) is turned into something a test can fail on.

9. Why can tensors of rank other than 2 not be function parameters yet, and what is the workaround?

    ??? note "Answer"
        The type syntax `tensor[RxC]`, the C++ header generator (`mgc lib`, which wraps a function's arguments as `mg::Matrix`) and the dynamic-shape machinery were all built for rank 2, and extending them was not part of this chapter's scope. The workaround is the one example 8 uses: pass a matrix (a `2x12` for a `2x3x4` tensor) and `reshape` it inside the function. The reshape is free, and the compiled function works for any values of that shape.

10. What would be needed to add a rank-N `+`?

    ??? note "Answer"
        An elementwise operation already exists in the dialect for any equal ranks (`mg.add`'s verifier compares rank and each dimension), but its lowering is a two-loop nest and the front end rejects non-matrices. Needed: a lowering that builds a loop nest of the operand's rank (as `mg.permute`'s already does), front-end shape rules for ranks above 2 (equal shapes; whether size-1 axes stretch), and tests with a definition-style reference as for `contract`.
