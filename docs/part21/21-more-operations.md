# 21. More Operations: Subtract, Hadamard, Divide, Matrix Product, and Scalars

**What you will understand:** how to grow a dialect by four operations and one kind of operand, end to end: the operation definitions, their verifiers, their lowerings, the front end's syntax for them, and the tests that prove each one. You will also meet the three different things "multiply" can mean for matrices (elementwise, matrix product, and by a scalar), learn why division by zero is not an error, and read the PTX for a reduction.

**What you need to know first:** the [language tour](../tour/language-tour.md) for the syntax, then Chapters 3 to 5 (defining and lowering an op; `mg.add` is the model for most of this chapter), 13 and 14 (dynamic shapes and the run-time check), and 20 (the language and the `mgc` driver). Each new idea is explained where it first appears.

## Compile and run: the commands for this chapter

Every code listing and sample output below was produced by these commands, run from `docs/part21/code/`:

```sh
./build.sh                         # compile mg-opt with the new ops           -> build/mg-opt
./mgc run examples/04_matmul.mg    # compile one example to native code and run it
./mgc ptx examples/13_gpu_matmul.mg  # compile one example to PTX (not run: no GPU here)
./demo.sh > demo_out.txt           # run all examples; the output below is this file
./show.sh                          # write the lowered MLIR shown below  -> show/
cpp/run.sh                         # build and run the C++ program       -> cpp/run_out.txt
cd ../../part15/code && ./run_lit.sh   # the whole test suite (78 tests)
```

## Primer: three meanings of "multiply"

Given two matrices **A** and **B**, three different operations are all called multiplication.

**Elementwise** (also the **Hadamard product**, after Jacques Hadamard) multiplies matching elements: `result[i][j] = A[i][j] * B[i][j]`. It needs the two matrices to have the same shape. It is the same kind of operation as the `mg.add` of Chapter 3, with `*` in place of `+`. Subtraction and division are the same again: `A - B` and `A / B`, taken element by element.

**The matrix product** is a different operation. For **A** of shape m by k and **B** of shape k by n, the result has shape m by n, and `result[i][j] = A[i][0]*B[0][j] + A[i][1]*B[1][j] + ... + A[i][k-1]*B[k-1][j]`: the dot product of row i of **A** with column j of **B**. The two shapes do not need to match; only the **inner dimensions** (the two k's) must. It is the operation behind most of machine learning and graphics. The summed term is called a **reduction**: many values are combined into one.

**By a scalar** combines every element with one number: `A * 2` doubles every element and `10 - A` subtracts every element from 10. A scalar has no shape, so there is nothing to check at run time.

Two more facts matter. First, **order matters** for subtraction, division and the matrix product: `A - B` is not `B - A`, and `A @ B` usually has a different shape than `B @ A`. Second, floating-point division follows the **IEEE 754** standard: `x / 0` is positive or negative **infinity** (`inf`), and `0 / 0` is **not a number** (`nan`). Neither is an error, and neither stops the program; the numbers simply propagate. Mountain Goat inherits this because it lowers to the hardware's own division.

## Design decisions

**One operator, one meaning.** The language already used `+`. For the new ones: `-` and `/` are elementwise; **`*` is the Hadamard (elementwise) product**; and **`@` is the matrix product** (the spelling Python uses). A language that overloads `*` to mean "elementwise or matrix product, depending on shapes" makes every reader work out which one it is; here it is always visible in the operator.

**Scalars are compile-time numbers.** A number like `2` or `0.5`, or a `let` bound to one (`let k = 2 + 3 * 4`, folded to 14 by the front end), combines with a matrix through one new operation, `mg.scalar`. Scalars are not run-time values in this language: you cannot read one out of a matrix, and you cannot print or pass one to a function.

**One operation for all scalar forms.** There are four arithmetic operations and two operand orders (`A - 1` versus `1 - A`), eight combinations. Rather than eight operations, `mg.scalar` carries three attributes: `op` (one of `"add"`, `"sub"`, `"mul"`, `"div"`), `value`, and `reversed` (`false` computes `x OP value`, `true` computes `value OP x`). The reversed flag exists because `10 - A` and `A - 10` differ, as do `1 / A` and `A / 1`. For `+` and `*` the flag is harmless but unnecessary; the front end sets it whenever the scalar is written on the left.

**Precedence.** Tightest first: unary minus, then `*`, `/` and `@` (left to right, all at one level), then `+` and `-`. So `a + a * a` is `a + (a * a)`, and `a - b @ a` is `a - (b @ a)`.

## The operations (`MgOps.td`)

The new definitions, in the same ODS language as Chapter 3:

```text
--8<-- "docs/part21/code/MgOps.td:42:114"
```

`SubOp`, `MulOp` and `DivOp` are copies of `AddOp`'s shape: two operands, one result, the same printed format. `AddOp` also has a constant folder; the new ones do not (the lowering still produces correct results for constant operands, just without compile-time folding). `NegOp` has one operand. `MatmulOp` has the same shape of declaration as `AddOp` but a different rule, in its verifier below. `ScalarOp` carries its three attributes in its `arguments`.

## The verifiers (`MgDialect.cpp`)

`SubOp`, `MulOp`, `DivOp`, `NegOp` and `ScalarOp` all share one rule: same rank, and each dimension compatible between every pair of types, where *compatible* is Chapter 13's rule (equal, or `?` on either side). Rather than copy `AddOp::verify` five times, one helper does it:

```cpp
--8<-- "docs/part21/code/MgDialect.cpp:78:126"
```

`mg.matmul` is the interesting one. It is **not** "same shape". It checks that the inner dimensions agree (`lhs` columns against `rhs` rows) and that the result is `lhs` rows by `rhs` columns, again using `compatibleDim` so `?` is accepted. `mg.scalar` additionally rejects any `op` that is not one of the four names. (A string attribute is used instead of an enum to keep the definition short; the verifier is the guard. An enum attribute would catch the same mistake earlier, and would be the better design for a larger dialect.)

## The lowerings (`LowerToAffine.cpp`)

**Subtract, multiply and divide** reuse the whole lowering of `mg.add` (Chapter 4 and 14): check shapes at run time where a dimension is `?`, allocate the result, run a two-deep loop nest, load both operands, apply one arithmetic operation, store. The only thing that differs is the arithmetic operation, so one C++ template takes it as a parameter:

```cpp
--8<-- "docs/part21/code/LowerToAffine.cpp:113:143"
```

The patterns are registered with `ElementwiseBinaryLowering<mg::SubOp, arith::SubFOp>`, and likewise for `MulOp`/`MulFOp` and `DivOp`/`DivFOp`. The run-time check's message names the operation (`mg.sub: operand shapes differ at runtime in dimension 0`), because the template passes `op.getOperationName()`.

**Scalar and negate** have one input, so there is no second operand to check:

```cpp
--8<-- "docs/part21/code/LowerToAffine.cpp:144:194"
```

The scalar is turned into one `arith.constant` outside the loop, and `reversed` decides which side of the arithmetic operation it goes on. You can see the result in the lowered code for `10 - x`:

```mlir
--8<-- "docs/part21/code/show/scalar_reversed_lowered.mlir"
```

(`arith.subf %cst, %0` with the constant first: that is the reversed form.)

**Matrix product** needs three nested loops and a run-time check of the inner dimension. The result is first filled with zeros, because the main loop *accumulates* into it (`result[i][j] += lhs[i][k] * rhs[k][j]`), and an uninitialized buffer holds garbage:

```cpp
--8<-- "docs/part21/code/LowerToAffine.cpp:195:245"
```

This is the lowered code for a static `2x3 @ 3x4`. Read it in two halves: the first loop nest zero-fills the 2x4 result; the second is the three-deep accumulate. The `k` loop (`%arg4`) is the reduction:

```mlir
--8<-- "docs/part21/code/show/matmul_static_lowered.mlir"
```

(Four `arith.constant` operations in the middle are unused leftovers of building the loop bounds; they are harmless and a later canonicalization pass would remove them.)

For a dynamic matmul the lowered code begins with the check. These are the first lines, showing the two `memref.dim` reads, the comparison, and the `cf.assert` with its message:

```mlir
--8<-- "docs/part21/code/show/matmul_dynamic_lowered.mlir:4:11"
```

The complete change against the earlier versions of these files (the operations, verifiers, lowerings, front end, driver and the PTX decoder):

??? note "The full diff for this chapter (click to expand)"
    ```diff
    --8<-- "docs/part21/code/chapter21.diff"
    ```

To rebuild `mg-opt` with everything above:

```sh
--8<-- "docs/part21/code/build.sh"
```

## The front end: new operators

The Chapter 20 front end parsed `+` and `transpose` only. Operator parsing now has the three levels from the design section, one small method each:

```python
--8<-- "docs/part21/code/mgfront.py:63:110"
```

`binary` is where each operator becomes an operation. Two matrices with `+ - * /` become the elementwise operation (shapes checked, `?` accepted); `@` becomes `mg.matmul` with the result shape built from the two inputs; a matrix and a number become `mg.scalar` (reversed when the number is on the left); and two numbers are folded on the spot (dividing a scalar by a scalar zero is an error there, since the front end can see it; dividing a *matrix* by zero is not, because that is IEEE). A scalar passed where a matrix is expected, printed, or returned from a function is rejected with a message.

## Fourteen examples

Every example lives in `docs/part21/code/examples/`. Each block below shows the program, the real output, and the exit status. Memref base addresses (`0x…`) vary and are masked. As in Chapter 20, the output format (`Unranked Memref ... data = [[...]]`) is MLIR's runtime printer, not Mountain Goat's.

### 1. Subtraction: order matters

```text
--8<-- "docs/part21/code/demo_out.txt:1:14"
```

`a - b` and `b - a` are negatives of each other, as arithmetic says.

### 2. The Hadamard product: elementwise

```text
--8<-- "docs/part21/code/demo_out.txt:16:26"
```

Each element is multiplied by the matching element (`3 * 2 = 6`, `5 * 3 = 15`). Compare with example 4, which uses the same kind of inputs but gives a different answer, because `@` is a different operation.

### 3. Division, and what happens at zero

```text
--8<-- "docs/part21/code/demo_out.txt:28:37"
```

`10/4 = 2.5` and `20/8 = 2.5`. The bottom row divides `0` by `0` and `-5` by `0`: the result is `-nan` and `-inf`, and the program exits normally with status 0. The sign shown on `nan` is whatever the hardware produced for `0/0` (x86 produces a negative quiet NaN); the book does not rely on it, and the test accepts either sign.

### 4. Matrix product

```text
--8<-- "docs/part21/code/demo_out.txt:39:53"
```

A 2x3 matrix times a 3x2 matrix is 2x2. Check the top-left entry by hand: row `[1, 2, 3]` dotted with column `[7, 9, 11]` is `7 + 18 + 33 = 58`. The second product, `b @ a`, is 3x3: reversing the operands changes the *shape*, not just the values.

### 5. Scalars, on either side

```text
--8<-- "docs/part21/code/demo_out.txt:55:83"
```

Six forms: `a + 10`, `a - 1`, `10 - a`, `a * 0.5`, `16 / a`, `a / 4`. Compare `a - 1` (`[[0, 1], [3, 7]]`) with `10 - a` (`[[9, 8], [6, 2]]`): the `reversed` flag is why they differ. `16 / a` divides 16 *by each element*.

### 6. Precedence

```text
--8<-- "docs/part21/code/demo_out.txt:85:111"
```

Five lines: `a + a * a`, `(a + a) * a`, `a - b @ a` (here `b` is the identity, so the answer is all zeros), `-a + 10`, and `a * k` where `k = 2 + 3 * 4 = 14`. The first two give different answers from the same symbols, which is what precedence means.

### 7. A linear layer

```text
--8<-- "docs/part21/code/demo_out.txt:113:121"
```

`x @ w + bias` is the core computation of one layer of a neural network: two samples (rows of `x`) are multiplied by a weight matrix and a bias is added. This is a toy: there is no learning and no activation function. The point is that matrix product and elementwise addition compose in one expression.

### 8. A Gram matrix

```text
--8<-- "docs/part21/code/demo_out.txt:123:136"
```

`a @ transpose(a)` is always square and always **symmetric** (the entry at row i, column j equals the one at row j, column i): look at `32` and `32`. Each entry is the dot product of two rows.

### 9. Identities you can check by eye

```text
--8<-- "docs/part21/code/demo_out.txt:138:159"
```

`a @ I = a`, `a - a = 0`, `a / a = 1` (wherever `a` is not zero) and `-(-a) = a`. When you add an operation to a compiler, checking such identities is a cheap, independent way to catch a lowering bug, because they hold regardless of what the numbers are.

### 10. One compiled matmul, many shapes

```text
--8<-- "docs/part21/code/demo_out.txt:161:175"
```

`mm` takes `tensor[?x?]` arguments, so it is compiled once. It is called with 2x3 times 3x1, then 1x2 times 2x2, then 1x1 times 1x1, and the results have sizes 2x1, 1x2 and 1x1.

### 11. Scalar operations on dynamic shapes

```text
--8<-- "docs/part21/code/demo_out.txt:177:193"
```

`affine` computes `a * 2 + 1` for any shape. No run-time shape check is needed here, because there is one matrix and a compile-time scalar.

### 12. When the inner dimensions disagree

```text
--8<-- "docs/part21/code/demo_out.txt:195:203"
```

2x3 times 2x2 has inner dimensions 3 and 2. The front end cannot see this (both parameters are `?`), so the program compiles and the **run-time check** aborts it: message on stderr, exit status 134, and nothing on stdout. That is Chapters 14 and 19 working for an operation they were not written for, because `mg.matmul` uses the same `cf.assert` that `mg.add` does.

### 13 and 14. The GPU path for the new operations

```text
--8<-- "docs/part21/code/demo_out.txt:205:255"
```

These are the instructions out of the real PTX that `mgc ptx` produced (compile-only: nothing was launched, and the PTX was never assembled with `ptxas`). Three things are worth reading:

1. **`matmul` becomes two kernels.** The first, which stores a zero, is the zero-fill loop nest. The second does the accumulate. Chapter 10's recipe parallelizes the loops it can prove safe (the `i` and `j` loops, one thread per result element), and leaves the `k` loop, the reduction, as an ordinary sequential loop inside each thread.
2. **The `k` loop is unrolled.** The four `mul.rn.f64` and `add.rn.f64` pairs, with load offsets `+8`, `+16`, `+24` (a row of the left operand) and `+32`, `+64`, `+96` (a column of the right one), are the four iterations of a 4x4 product, because `k` is the constant 4. Each thread loads, multiplies, adds and stores the running sum back, four times.
3. **Elementwise chains become several kernels.** `(a - b) * a / 2 + 1` is four loop nests, hence four kernels (`sub.rn.f64`, `mul.rn.f64`, `div.rn.f64`, `add.rn.f64`), each reading the previous one's buffer. No fusion happened (Chapter 18 explains why fusion is conservative).

Two honest corrections are needed here. First, the very first attempt on `matmul` **failed** with `failed to legalize operation 'builtin.unrealized_conversion_cast' that was explicitly marked illegal`. The cause: the sequential `k` loop lowers to an `scf.for` inside the GPU module, and Chapter 10's device pipeline had no pass to turn structured loops into branches before `convert-gpu-to-nvvm`. Adding `convert-scf-to-cf` inside `gpu.module(...)` fixed it; Chapter 10's own examples never had a loop in a kernel, which is why the gap never showed. Second, Chapter 10's `decode_ptx.py` printed only the *first* kernel's PTX, so the first look at example 14 appeared to contain one kernel when it had four (`grep -c assembly` on the binary showed 4). This chapter ships a corrected `decode_ptx.py` (it prints every kernel).

Whether the kernels *compute the right answer* on a GPU is not established. Nothing here was run on one. What was checked is that the CPU path (examples 1 to 12) gives correct results for the same operations, and that the GPU path produces PTX of the expected structure.

### Errors

```text
--8<-- "docs/part21/code/demo_out.txt:257:272"
```

Both are caught by the front end, with the line number, before any MLIR exists.

## Using the new operations from C++

`mgc lib` generates a C++ header for any set of `def`s (Chapter 20). The Mountain Goat source for six functions:

```text
--8<-- "docs/part21/code/cpp/ops.mg"
```

A C++ program calls them and, for `matmul`, **compares the result against a plain C++ triple loop** on two inputs: the 2x3 by 3x2 example, and a 7x5 by 5x9 pair of generated matrices (an independent check, since the reference is not compiled by Mountain Goat):

```cpp
--8<-- "docs/part21/code/cpp/app.cpp"
```

```sh
--8<-- "docs/part21/code/cpp/run.sh"
```

```text
--8<-- "docs/part21/code/cpp/run_out.txt"
```

Both comparisons print `yes`. The second run, `./app mismatch`, calls `matmul` on a 2x3 and a 2x3, and the compiled code aborts with its message, as in example 12.

## Tests

Fifteen new tests in `test/ops/`, and three more in `test/tour/` for the language tour (suite: 78). Like Chapter 20's, the program tests run the real example files rather than copies.

| Test | What it checks |
|---|---|
| `matmul-inner-mismatch` | the verifier's exact message for a static inner-dimension mismatch |
| `matmul-bad-result-shape` | `(2x3)@(3x4)` declared as `2x3` is rejected |
| `scalar-bad-op` | `mg.scalar` with `op = "pow"` is rejected |
| `elementwise-static-mismatch` | `sub`, `mul` and `div` each reject a static mismatch (three split inputs) |
| `dynamic-accepted` | `?` dimensions verify and the new ops print and re-parse |
| `matmul-lowering-structure` | the static form has a zero-fill nest and a three-deep nest with `mulf`/`addf` and no assert; the dynamic form has the assert with its exact message |
| `values` | examples 1, 2, 4, 5: subtract, Hadamard, matmul, scalars, with exact values |
| `division-ieee` | `2.5`, `nan`, `inf` and no abort |
| `precedence-and-identities` | examples 6 and 9 |
| `composed-programs` | the linear layer and Gram matrices |
| `dynamic-ops` | examples 10 and 11 |
| `matmul-mismatch-aborts` | run-time abort, message on stderr, empty stdout |
| `front-end-errors` | both error files, exact text |
| `ptx-new-ops` | the GPU path: four kernels for the chain, two for matmul, with the arithmetic instructions |
| `cpp-interop-ops` | the C++ program builds with `-Wall -Werror`, matches the plain C++ loops, and aborts with the message on mismatch |

Do the tests fail when the code is wrong? `prove_tests_can_fail.sh` runs the new tests against Chapter 20's `mg-opt` (which has none of the new ops) and against six broken copies of the front end and driver:

```sh
--8<-- "docs/part21/code/prove_tests_can_fail.sh"
```

```text
--8<-- "docs/part21/code/prove_tests_can_fail_out.txt"
```

Front-end bugs are cheap to inject. Bugs in the lowering need `mg-opt` rebuilt (a full rebuild each), so `lowering_mutation.sh` injects five, one at a time, into a copy of the source tree:

```sh
--8<-- "docs/part21/code/lowering_mutation.sh"
```

```text
--8<-- "docs/part21/code/lowering_mutation_out.txt"
```

Read the second list closely: **removing the zero-fill is caught by only two of the fifteen tests**, the lowering-structure test and the 7x5-by-5x9 comparison in the C++ test. None of the tests that print small results noticed, because `malloc` returned fresh, already-zero memory for a small buffer, so the accumulators happened to start at zero anyway. The bug is real and the program is wrong, but it would pass every small example by luck. This is exactly why the structure test (which looks for the zero-fill loop) and the larger independent comparison exist, and a reminder that a test which passes on a tiny input proves little about memory the program forgot to initialize.

The same list shows the three other groups of tests doing their jobs. Ignoring the `reversed` flag is caught by `values`; dropping the run-time inner-dimension check is caught by three tests; compiling `div` as a multiply, and compiling `neg` as the identity, are caught by the tests that check results (`division-ieee`, `precedence-and-identities`). Notice that `neg` is caught by only one test; the `values` test does not use negation at all.

The full suite against the Chapter 21 build:

```text
--8<-- "docs/part15/code/run_out_78.txt"
```

## Bugs found while writing the language tour

Writing the tour page (`docs/tour/language-tour.md`) with real, runnable examples found two problems in this chapter's front end, both now fixed and covered by tests:

- **Scientific notation broke the compiled program.** The front end accepted `3e2` but copied it into the MLIR, and MLIR only accepts a decimal point before an exponent (`3.0e2`). The error came from MLIR (`expected ']'`), pointing into a file the user never wrote. The front end now rewrites every number through one helper (`mlir_float`), and `scientific-literals` checks the MLIR text and the compiled result (including a scalar with a large exponent, `1e20`).
- **Two confusing messages.** A `def` with no expression (for example, putting a `let` in its body) produced `unexpected None`, and `tensor[0x3]` was accepted. They now say `expected an expression, found the end of the line` and `bad dimension '0': use a positive integer or '?'`.

## Limits and what is not established

- **Rank 2, `f64` only.** No other ranks, no other element types, no integer arithmetic.
- **No broadcasting.** `a + b` needs equal shapes (or `?` resolved at run time). You cannot add a row vector to every row of a matrix.
- **No compile-time folding** for the new operations (only `mg.add` has a folder). `1 + 1`-style scalar arithmetic is folded by the front end, but `mg.sub` of two constant matrices is computed at run time.
- **`mg.scalar` uses a string attribute** for its operation name; an enum would be stricter.
- **Matrix product is the textbook triple loop.** No tiling, no blocking, no vectorization, no library call. **No performance claim is made at all**, and nothing here measures speed.
- **Floating-point caveats:** the matrix product's sum order is the loop order, and floating-point addition is not associative, so a different order (say, a GPU running the reduction differently, or a library) can give slightly different results. Division by zero produces `inf`/`nan` silently.
- **The bufferization path (Chapter 6) was not extended.** `--one-shot-bufferize` knows `mg.add` and `mg.transpose` only. The new operations lower through the hand-written conversion, which `mgc` uses.
- **GPU:** PTX is produced and its structure is inspected. It was never assembled, loaded or launched, and its correctness and speed on a GPU are **not established**. The matmul kernels are one-thread-per-output-element with a sequential reduction, nothing cleverer.
- **Platform:** x86-64 Linux, LLVM 18.1.3. POSIX only (Chapter 19).
- **The language itself is described in the [language tour](../tour/language-tour.md).** This chapter only adds operations to it.

## Reproducing

```sh
cd docs/part21/code
./build.sh && ./demo.sh > demo_out.txt && ./show.sh && cpp/run.sh
./prove_tests_can_fail.sh            # front-end mutations (a few seconds)
./lowering_mutation.sh               # lowering mutations (a full rebuild each: roughly 10 minutes)
cd ../../part15/code && ./run_lit.sh # 78 tests
```

## Chapter summary

- Four new operations and one new operand kind: `mg.sub`, `mg.mul` (Hadamard), `mg.div`, `mg.neg`, `mg.matmul`, and `mg.scalar` (add, sub, mul, div with a number, on either side).
- `*` is elementwise and `@` is the matrix product: one operator, one meaning.
- Elementwise operations share one verifier and one lowering template; `matmul` is a zero-fill plus a three-deep accumulate loop, with one run-time check of the inner dimensions; `scalar` needs no check at all.
- Division follows IEEE 754: `x/0` is `inf` or `nan`, not an error.
- Fourteen worked examples ran for real, including a linear layer, a Gram matrix, a dynamic matmul and a run-time abort.
- The GPU path produced PTX for all of it, which exposed two real gaps (no `scf-to-cf` for loops inside kernels; a decoder that printed only the first kernel), both fixed.
- C++ calls the new operations and matches a plain C++ loop on a 7x5 by 5x9 product.
- Fifteen new tests (plus three for the tour, 78 total), each shown able to fail.

## Self-check questions

Each answer is collapsed; try the question first.

1. What are the three meanings of "multiply" for matrices, and which operator in Mountain Goat is each?

    ??? note "Answer"
        **Elementwise (Hadamard):** each element times the matching element, written `*`, needs equal shapes. **Matrix product:** row-by-column dot products, written `@`, needs only the inner dimensions to match and gives (rows of the left) by (columns of the right). **By a scalar:** every element times one number, written `*` with a number on one side. The language disambiguates by operator and by operand type (matrix or number), never by guessing from shapes.

2. Why does `a - 1` give a different answer from `10 - a`, and how does the compiler represent the difference?

    ??? note "Answer"
        Subtraction is not commutative: `a - 1` subtracts 1 from each element, while `10 - a` subtracts each element from 10. Both are `mg.scalar` with `op = "sub"`; the `reversed` attribute is `false` for the first and `true` for the second. The lowering uses it to decide which side of `arith.subf` the constant goes on (`subf %0, %cst` versus `subf %cst, %0`). The same applies to division (`16 / a` versus `a / 16`).

3. What is a reduction, and which loop in the lowered matmul is one?

    ??? note "Answer"
        A reduction combines many values into one, here by summing. In the lowered matrix product it is the innermost loop over `k`: for each output position `(i, j)`, it sums `lhs[i][k] * rhs[k][j]` over all `k` into the same memory location. The `i` and `j` loops are independent of each other (each result element is its own computation), which is why the GPU recipe makes them parallel and leaves the `k` loop sequential inside each thread.

4. Why must the result of a matmul be zero-filled first?

    ??? note "Answer"
        The main loop *accumulates*: it reads the current value at `result[i][j]`, adds a product, and writes it back. `memref.alloc` gives memory with unspecified contents, so without the fill every sum would start from garbage. The lowering therefore runs a separate loop nest that stores 0.0 everywhere before the accumulate nest. One of this chapter's mutations removes exactly this step, and the tests fail.

5. `mg.matmul`'s verifier does not require the two operand shapes to be equal. What does it require, and what happens when a dimension is `?`?

    ??? note "Answer"
        It requires the inner dimensions to be compatible (the left operand's columns against the right operand's rows) and the result to be (left rows) by (right columns). "Compatible" is Chapter 13's rule: equal, or `?` on either side. When the inner dimension is `?` on either side, the verifier accepts it, and the lowering emits one `cf.assert` that compares the two extents at run time. A failed check aborts with `mg.matmul: inner dimensions differ at runtime` on stderr.

6. Dividing a matrix by zero does not stop the program, but dividing a *scalar* by a scalar zero in source is an error. Why the difference?

    ??? note "Answer"
        Matrix division is carried out at run time by the hardware's floating-point divide, which follows IEEE 754: `x/0` gives `inf` or `-inf` and `0/0` gives `nan`; there is no exception to raise. Scalar-by-scalar arithmetic is folded by the *front end* while compiling, where a literal division by zero is certainly a mistake it can see and report with a line number. The front end cannot tell what a matrix will contain, so it does not guess.

7. Why did the first attempt to compile `matmul` to PTX fail, and why had Chapter 10 not hit that?

    ??? note "Answer"
        The `k` loop stays sequential, so it ends up as an `scf.for` *inside* the GPU kernel. The device pipeline from Chapter 10 converted the GPU dialect to NVVM but never converted structured loops (`scf`) to branches (`cf`), so a leftover cast could not be legalized. Chapter 10's kernels had no loops inside them (every loop became a thread index), so the missing pass was never needed. Adding `convert-scf-to-cf` inside `gpu.module(...)` fixed it.

8. Why does `(a - b) * a / 2 + 1` produce four kernels, and what does that say about the generated code?

    ??? note "Answer"
        Each operation lowers to its own loop nest over its own result buffer, and each nest becomes one kernel. So four operations give four kernels, each reading the previous one's output from memory and writing a new buffer. Nothing fused them into one pass over the data. That is correct but does more memory traffic than a fused version would; the book does not measure it and makes no speed claim.

9. The test `matmul-mismatch-aborts` checks stdout as well as stderr. What does the stdout check establish?

    ??? note "Answer"
        That the abort happens *before* anything is printed: the program printed nothing to stdout, and the message went only to stderr. Without that check, a bug that printed a partial or wrong result and *then* aborted would pass.

10. The C++ test compares Mountain Goat's matmul against a hand-written C++ triple loop. Why is that a stronger check than the values in example 4?

    ??? note "Answer"
        Example 4's expected values were computed by hand for one small pair of matrices; the C++ comparison checks 7x5 by 5x9 matrices with 63 outputs, against an implementation that Mountain Goat did not produce. A bug that coincidentally gives the right numbers on a tiny input (say, a transposed index that happens to be symmetric) is unlikely to survive a non-square, non-symmetric comparison.
