# 22. Broadcasting, Reductions and relu: Enough Operations for a Neural-Network Layer

<p style="text-align:center"><img src="../assets/goats/ch-22.svg" alt="Mountain goats on the mountain in black and white" style="max-width:100%;height:auto;border-radius:6px"></p>

**What you will understand:** how to express "add this row to every row", "total each column" and "clamp negatives to zero", the three ideas (broadcasting, reduction, an activation function) that turn matrix arithmetic into a neural-network layer. You will see how each becomes loops, why broadcasting is a rule about shapes and not new arithmetic, what a reduction does to a shape, and why a test suite can pass while a real bug hides in it.

**What you need to know first:** the [language tour](../tour/language-tour.md) (syntax and shapes), Chapter 21 (the elementwise operations and `@`), and Chapters 13 and 14 for what `?` means and what is checked at run time.

!!! tip "Compile and run"
    ```sh
    cd docs/part22/code
    ./build.sh                                  # builds ./build/mg-opt (Chapter 22's)
    ./mgc run examples/07_mlp_layer.mg          # compile one example to native code and run it
    ./mgc ptx examples/10_gpu_layer.mg          # compile one example to PTX (not run: no GPU here)
    ./demo.sh > demo_out.txt                    # all the examples; the output on this page is this file
    ./show.sh                                   # the lowered MLIR shown below  -> show/
    cpp/run.sh                                  # build and run the C++ program
    cd ../../part15/code && ./run_lit.sh        # the whole test suite
    ```
    Every listing and output on this page comes from these commands.

!!! note "Why this page shows FAIL lines, and why that is good"
    Parts of this page come from **negative controls**: the same tests run against an *older* build, or against *deliberately broken* code (a "mutation"). In those runs a **FAIL is the expected, wanted result**: it means a test noticed the problem, which is how we know the tests are worth anything. What would be wrong is the opposite, a deliberately broken build that passes everything. The **baseline** (the unmodified current build) must always show every test passing, and it does. Each script that does this says so in its own header and prints a reminder at the top of its output.

## Primer: three ideas

**Broadcasting.** `[[1, 2, 3], [4, 5, 6]] + [[10, 20, 30]]` adds a 1x3 row to a 2x3 matrix. The shapes differ, so by Chapter 21's rule the program would be an error. But the intent is clear and extremely common (adding a *bias* to every row). **Broadcasting** is the rule that makes it legal: a dimension of size 1 is conceptually *repeated* to match the other operand, so the 1x3 row behaves as if it were two copies of itself stacked into a 2x3 matrix. Broadcasting is not a new arithmetic operation; it only changes shapes before the operation runs. The rule, per dimension: the sizes must be equal, or one of them must be 1 (in which case it grows to the other).

**Reductions.** A **reduction** combines many numbers into one: the sum of a row, the largest of a column. For a matrix there are two natural directions. This book names them by what you get: `row_sum(a)` gives **one value per row** (an M by 1 result, each row collapsed to a single number), and `col_sum(a)` gives **one value per column** (a 1 by N result). The same pair exists for `max` and for `mean`. The reduced dimension becomes size 1, which is exactly what lets the result be broadcast back against the original: `a - col_mean(a)` subtracts each column's average from that column.

**Activation functions.** A neural-network layer computes `x @ w + bias` and then applies a nonlinear function elementwise. The simplest and most common is **relu** (rectified linear unit): `relu(x) = max(x, 0)`, which turns every negative number into zero and leaves the rest unchanged. Without it, stacking layers would collapse into one big matrix product.

Put together, `relu(x @ w + bias)` is one layer, and it uses everything this chapter adds. That is the target.

## Design decisions

- **Names say what you get.** `row_sum` returns one value per row. A name like `sum(a, axis=1)` makes you remember which axis is which; these do not.
- **Broadcasting is implicit and static.** A size-1 dimension is broadcast automatically by `+ - * /`, and the front end inserts an explicit `mg.broadcast` operation to do the repetition, so every later stage sees plain equal-shape arithmetic. It works only when the shapes involved are **static** (known numbers). A `?` dimension is **never** broadcast: its size is unknown until the program runs, so it must be equal to the other operand's size at run time, exactly as in Chapter 14.
- **Mean needs a count.** `row_mean` is a sum divided by the number of columns. That number must be known when compiling, so `row_mean` on a `?`-wide matrix is a compile error (the other reductions work on `?`).
- **`relu` propagates NaN.** `relu` lowers to a floating-point `maximum` that returns NaN if the input is NaN, rather than hiding it as 0. That matches how most ML frameworks treat it, and it is what NVIDIA's `max.NaN` instruction does.

## The operations (`MgOps.td`)

Three new definitions, in the same ODS language as Chapters 3 and 21:

```text
--8<-- "docs/part22/code/MgOps.td:85:112"
```

`mg.relu` is a one-input elementwise op, like `mg.neg`. `mg.reduce` carries two attributes: `axis` (1 means "combine the elements of each row", giving an M by 1 result; 0 means "each column", giving 1 by N) and `kind` (`"sum"` or `"max"`). Mean is not a separate operation: the front end emits a sum followed by a divide by the (static) count. `mg.broadcast` has one operand and an explicit result type; its verifier says what shapes are allowed.

## The verifiers (`MgDialect.cpp`)

```cpp
--8<-- "docs/part22/code/MgDialect.cpp:110:140"
```

`mg.relu` reuses Chapter 21's shared elementwise check. `mg.reduce` checks the axis, the kind, and that the result collapsed *exactly* the reduced axis to size 1 and kept the other (accepting `?`). `mg.broadcast` requires static shapes and allows an input dimension to differ from the result only if it is 1.

## The lowerings (`LowerToAffine.cpp`)

**relu** is Chapter 21's negate with `maximumf(x, 0)` instead of `negf`:

```cpp
--8<-- "docs/part22/code/LowerToAffine.cpp:175:198"
```

**reduce** is the new idea. It cannot be a single loop nest that stores each output once, because each output combines many inputs. Instead it runs *two* nests: the first writes the starting value into every output cell (0 for a sum, negative infinity for a max, because `max(x, -infinity)` is always `x`); the second walks the **input** and folds every element into the output cell it belongs to (`result[i][0]` when reducing a row, `result[0][j]` when reducing a column):

```cpp
--8<-- "docs/part22/code/LowerToAffine.cpp:199:236"
```

Here is the real lowered code for `row_sum` of a 2x3 matrix. The first nest (over a 2x1 output) fills with zero; the second walks the 2x3 input and adds each element into the cell of its row:

```mlir
--8<-- "docs/part22/code/show/reduce_row_sum_lowered.mlir"
```

**broadcast** walks the *result* and reads the input with index 0 in any dimension where the input has size 1. No arithmetic, only a different way of indexing:

```cpp
--8<-- "docs/part22/code/LowerToAffine.cpp:237:258"
```

```mlir
--8<-- "docs/part22/code/show/broadcast_row_lowered.mlir"
```

The row `%arg0[%c0, %arg2]` is read with the first index fixed at 0 for every row `%arg1` of the result: the single input row is repeated.

The complete change against Chapter 21's files:

??? note "The full diff for this chapter (click to expand)"
    ```diff
    --8<-- "docs/part22/code/chapter22.diff"
    ```

To rebuild `mg-opt`:

```sh
--8<-- "docs/part22/code/build.sh"
```

## The front end

Two additions to `mgfront.py`. First, the **broadcast rule**, applied to every elementwise operator. For each pair of dimensions it picks the result size (equal sizes, or `?`, stay as they are; a static 1 grows to the other side's size; anything else is an error) and then `grow` inserts an `mg.broadcast` for any operand that needs one:

```python
--8<-- "docs/part22/code/mgfront.py:112:131"
```

Second, the **built-in functions** (`relu`, and `row_` / `col_` followed by `sum`, `max` or `mean`), which turn into `mg.relu` or `mg.reduce`, with mean followed by a divide by the static count:

```python
--8<-- "docs/part22/code/mgfront.py:150:166"
```

And here is what the front end emits for a whole layer, `relu(x @ w + bias)`, where `bias` is a 1x2 row and `x @ w` is 2x2. The `mg.broadcast` on the third line was inserted automatically:

```mlir
--8<-- "docs/part22/code/show/mlp_layer_front_end.mlir:1:6"
```

## Thirteen examples

Each block shows the program, its real output, and the exit status. Memref base addresses (`0x…`) are masked.

### 1. relu

```text
--8<-- "docs/part22/code/demo_out.txt:1:9"
```

### 2. Row sums and column sums

```text
--8<-- "docs/part22/code/demo_out.txt:10:22"
```

`row_sum` gives a 2x1 column (one total per row: `1+2+3 = 6`, `4+5+6 = 15`); `col_sum` gives a 1x3 row (one total per column: `5, 7, 9`).

### 3. Max and mean

```text
--8<-- "docs/part22/code/demo_out.txt:23:42"
```

`row_mean` of the first row `[1, 9, 3]` is `13/3 = 4.33333`; the printer shows six significant digits.

### 4. Broadcasting a bias

```text
--8<-- "docs/part22/code/demo_out.txt:43:62"
```

A 1x3 row is added to every row; a 2x1 column is added to every column; a 1x1 matrix scales everything (`[[2]]` behaves like the scalar 2, which is why a scalar is simpler when it is all you need).

### 5. Centering columns

```text
--8<-- "docs/part22/code/demo_out.txt:63:77"
```

`a - col_mean(a)` subtracts each column's mean (2 and 30 here) from that column. The check after it, `col_sum(centered)`, is exactly `[[0, 0]]`: a centered column adds up to zero. This is a property that holds *whatever the lowering does*, so it is a good independent test of reductions, broadcasting and mean together.

### 6. Normalizing rows

```text
--8<-- "docs/part22/code/demo_out.txt:78:92"
```

Dividing each row by its own sum makes every row add to 1 (the second output confirms it).

### 7. A neural-network layer

```text
--8<-- "docs/part22/code/demo_out.txt:93:102"
```

`relu(x @ w + bias)`: a matrix product, a broadcast add and an activation, in one expression. Check the top-left value by hand: row `[1, 2, 3]` times column `[1, 0, 1]` is `4`, plus bias `0.5` is `4.5`, and relu keeps it. The top-right: `-1 + 2 + 0 = 1`, plus `-10` is `-9`, and relu clamps it to `0`. The second sample's whole row is negative, so it becomes zeros.

### 8. Two layers

```text
--8<-- "docs/part22/code/demo_out.txt:103:112"
```

Two layers and a final `row_max`, the largest value in each row. By hand: `[1, 1]` goes through layer one to `[3, 1]`, layer two to `[2]` and finally to `[2, 4]`, whose max is `4`; the second row ends as `[0, 0]`, max `0`.

### 9. Reductions on dynamic shapes

```text
--8<-- "docs/part22/code/demo_out.txt:113:136"
```

`totals` and `peaks` take `tensor[?x?]`, so each is compiled once and handles 2x3, 4x1 and 3x2 inputs. The last line is `relu(-[[1,2],[3,4]] + 2)`: unary minus, then a scalar add, then relu.

### 10. `?` is never broadcast

```text
--8<-- "docs/part22/code/demo_out.txt:137:149"
```

The first call has one row, which matches the 1x3 bias exactly, so it works. The second call has two rows, and because that dimension is `?` the program compares sizes at run time instead of broadcasting, and **aborts** with the message on stderr (Chapters 14 and 19). If you want the broadcast, the row count must be a static number in the type.

### 11. Broadcasting from the left

```text
--8<-- "docs/part22/code/demo_out.txt:150:172"
```

The small operand can be on either side, and operand order is preserved: `row - a` is `10-1, 20-2, 30-3` (left minus right), not the reverse. **This example was added after a mutation test found it missing** (see Tests below).

### 12. The max of negative numbers

```text
--8<-- "docs/part22/code/demo_out.txt:173:185"
```

The largest of `-3` and `-1` is `-1`, not `0`. This looks too obvious to test, and for exactly that reason it was not tested at first: a max reduction that started from 0 instead of negative infinity gets every earlier example right (they all have positive numbers) and only fails here. **This example was added after a mutation test found it missing** (see Tests below).

### 13. The GPU path

```text
--8<-- "docs/part22/code/demo_out.txt:186:215"
```

These are real PTX instructions from `mgc ptx` (compile-only: nothing was launched or assembled with `ptxas`). Five loop nests make five kernels: broadcast (a load and a store), add, relu (note `max.NaN.f64`, the NaN-propagating maximum), the reduction's zero-fill, and the reduction's accumulate. In the last, the three `add.rn.f64` instructions are the **sequential** loop over the three columns, unrolled (the `+8` and `+16` offsets are the second and third columns): each GPU thread owns one row and sums its three elements. The compiler parallelized the row loop and correctly left the reduction loop sequential.

### Errors

```text
--8<-- "docs/part22/code/demo_out.txt:216:229"
```

## Using it from C++

```text
--8<-- "docs/part22/code/cpp/ops.mg"
```

A C++ program calls each function on matrices larger than any example (7x5, 4x6 by 6x3, 5x4) and compares every result with a plain C++ loop it wrote independently:

```cpp
--8<-- "docs/part22/code/cpp/app.cpp"
```

```sh
--8<-- "docs/part22/code/cpp/run.sh"
```

```text
--8<-- "docs/part22/code/cpp/run_out.txt"
```

All five match.

## Tests

Ten new test files in `test/broadcast/` (the suite now has 88 tests). As in earlier chapters, program tests run the real example files.

| Test | What it checks |
|---|---|
| `verifier-reduce` | bad axis, bad kind, and a result that does not collapse the axis: exact messages |
| `verifier-broadcast` | a dimension that cannot grow, and a dynamic shape: exact messages |
| `roundtrip-and-lowering` | the three ops parse and print; the reduction has a `-infinity` start, two nests and no run-time check; the broadcast reads index 0 |
| `values` | relu, sums, max, mean, broadcasting (including from the left): exact numbers |
| `identities` | centered columns sum to 0; normalized rows sum to 1 |
| `networks` | the layer and the two-layer network |
| `dynamic-reductions` | reductions on `?` shapes; `?` is never broadcast (abort with the message) |
| `front-end-errors` | the two front-end errors, exact text |
| `ptx-layer` | five kernels, `max.NaN.f64`, a sequential reduction |
| `cpp-interop-reductions` | the C++ program builds with `-Wall -Werror` and all five comparisons match |

`prove_tests_can_fail.sh` runs them against Chapter 21's `mg-opt` (none of the new ops exist) and five broken copies of the front end:

```sh
--8<-- "docs/part22/code/prove_tests_can_fail.sh"
```

```text
--8<-- "docs/part22/code/prove_tests_can_fail_out.txt"
```

**Two runs found holes in the tests.** The first time the front-end mutations ran, the mutation "a size-1 left operand is not broadcast" made **no test fail** (`Passed: 10`, no failures): every example put the small operand on the right (`a + bias`), so the left-hand branch of the front end's broadcast rule was never exercised. The left-broadcast example (`12_broadcast_left.mg`, section 11 below) and a new check in `values` were added, the mutation was rerun, and it is now caught. A test suite is evidence only for what it exercises; a mutation is the way to find what it does not.

Lowering bugs need `mg-opt` rebuilt, so `lowering_mutation.sh` injects each into a copy of the source tree:

```sh
--8<-- "docs/part22/code/lowering_mutation.sh"
```

```text
--8<-- "docs/part22/code/lowering_mutation_out.txt"
```

**The second hole.** The first lowering mutation, "max reduction starts at 0 instead of -infinity", was run before the negative-max example (`13_negative_max.mg`, section 12 below) existed. It was caught by only **two** of the ten test files (the lowering-structure test, which looks for the `-infinity` constant, and the C++ comparison, whose generated data happens to include a column of all-negative numbers). Every hand-sized example passed, because none had a column whose maximum is negative. The first run's result:

```text
### lowering mutation: max reduction starts at 0 instead of -infinity
FAIL: broadcast/roundtrip-and-lowering.mlir (5 of 10)
FAIL: broadcast/cpp-interop-reductions.mlir (9 of 10)
  Passed  :  8 (9.09%)
  Failed  :  2 (2.27%)
```

The negative-max example and a check in `values` were added, and the whole mutation run was repeated; the listing above is the repeat, in which that mutation now also fails `values`.

**The third: a mutation that changes nothing you can see.** "Reduce over axis 1 writes into the wrong cell" stores each row's running total at `result[0, i]` instead of `result[i, 0]`. It passed **every** test, and no test of the numbers could ever catch it. The reason is that the result of a row reduction is M by 1, and in row-major memory the element at `[0, i]` has the same address as `[i, 0]` (the offset is `row * 1 + column`, and one of the two indices is 0). The program writes outside the declared shape (in the abstract language that is out of bounds) but into exactly the memory that the correct version would have used, so the outputs are identical. A bug whose effect is invisible in the output is called an **equivalent mutant**, and behavioral tests cannot see it. A structural check can: `roundtrip-and-lowering` now also requires that the row reduction loads and stores `%alloc[%arg, %c0]` (row index first, constant zero second), and with that check the mutation fails one test. It is a fair question whether such a check tests behavior or implementation. Here it does the latter, deliberately, because the behavior is indistinguishable and the implementation is wrong: on a different layout, or after a later optimization that trusts the declared bounds, the bug would surface.

The full suite against the Chapter 22 build:

```text
--8<-- "docs/part15/code/run_out_88.txt"
```

## Limits and what is not established

- **Rank 2, `f64` only**, as before.
- **Broadcasting is static only.** A `?` dimension is never broadcast; it must match at run time. No broadcasting for `@`.
- **Mean needs a static count**; `row_mean` on a `?`-sized axis is rejected.
- **Only `sum` and `max`** reductions (plus mean, built from sum). No `min`, `argmax`, product, or reduction over both axes at once.
- **`relu` and NaN:** `relu(NaN)` is NaN by design. No test feeds a NaN in (the language has no NaN literal; you can produce one with `0/0`, but this chapter does not test it).
- **Sum order and precision:** a reduction adds in loop order. Floating-point addition is not associative, so other orders (a GPU, a library) can differ in the last digits. The C++ comparison tolerates 1e-9.
- **No performance claim.** The reductions are plain loops, and the GPU kernels are one thread per output row with a sequential inner loop; none of this was timed.
- **GPU:** PTX produced and inspected, never assembled, loaded or launched. Correctness on a GPU is not established.
- **Bufferization (Chapter 6):** not extended; the new operations lower through the hand-written conversion that `mgc` uses.
- **Platform:** x86-64 Linux, LLVM 18.1.3, POSIX only.

## Reproducing

```sh
cd docs/part22/code
./build.sh && ./demo.sh > demo_out.txt && ./show.sh && cpp/run.sh
./prove_tests_can_fail.sh            # front-end mutations (seconds)
./lowering_mutation.sh               # lowering mutations (a full rebuild each: roughly 10 minutes)
cd ../../part15/code && ./run_lit.sh # 88 tests
```

## Chapter summary

- Three new operations: `mg.relu`, `mg.reduce` (sum or max along an axis) and `mg.broadcast`; the front end adds `relu`, `row_` and `col_` `sum`, `max` and `mean`, and broadcasts a static size-1 dimension automatically.
- A reduction needs two loop nests (initialize, then fold the input into the output) and shrinks one dimension to size 1, which is what makes `a - col_mean(a)` possible.
- Broadcasting changes shapes, not arithmetic: the front end inserts an explicit `mg.broadcast`, and later stages see ordinary equal-shape operations. A `?` dimension is never broadcast; it is checked at run time.
- `relu(x @ w + bias)` runs: a real neural-network layer, and a two-layer network, with values checked by hand.
- C++ calls it and matches independent plain loops; PTX is produced for all of it.
- A mutation test found a real gap (broadcasting from the left was untested); it is fixed and covered.

## Self-check questions

Each answer is collapsed; try the question first.

1. What does broadcasting do, and what is the rule for when two shapes can be broadcast together?

    ??? note "Answer"
        A dimension of size 1 is conceptually repeated to match the other operand, so `[[10, 20, 30]]` (1x3) can be added to a 2x3 matrix as if it were two stacked copies. Per dimension, the sizes must be equal or one of them must be 1; otherwise the shapes cannot be broadcast. It changes only shapes, not the arithmetic. In Mountain Goat the rule applies only to static dimensions.

2. Why is `?` never broadcast?

    ??? note "Answer"
        A `?` dimension's size is unknown when the program is compiled, so the compiler cannot know whether it is 1 (and so repeatable) or not. Guessing would silently change the meaning of a program depending on its inputs. Instead the dimension must equal the other operand's at run time, and a mismatch aborts with a message (example 10). To get broadcasting, write a static size in the type.

3. What is the difference between `row_sum(a)` and `col_sum(a)`, and what shapes do they return for a 2x3 matrix?

    ??? note "Answer"
        `row_sum` gives one total per row, a 2x1 result (the three columns collapse). `col_sum` gives one total per column, a 1x3 result (the two rows collapse). The name says what you get one of; the reduced dimension becomes size 1.

4. Why does `mg.reduce` lower to two loop nests instead of one?

    ??? note "Answer"
        Each output element combines several input elements, so it must start from a known value and then accumulate. The first nest stores the starting value (0 for a sum, negative infinity for a max) into every output cell; the second walks the input and folds each element into its output cell. A single nest that stored each output once would not have anywhere to accumulate.

5. Why does a max reduction start at negative infinity rather than at 0?

    ??? note "Answer"
        `max(x, -infinity) = x` for every `x`, so the starting value never affects the answer. Starting at 0 would be wrong whenever every element is negative: the result would be 0, a number that is not in the data at all. (This is one of the lowering mutations; see the results above for whether the tests catch it.)

6. What is `a - col_mean(a)` for a 3x2 matrix `a`, shape by shape?

    ??? note "Answer"
        `col_mean(a)` is 1x2 (one mean per column). Subtracting a 1x2 from a 3x2 broadcasts the 1x2 across the three rows, so every element has its own column's mean subtracted. The result is 3x2, and each column of it sums to zero.

7. Why is `row_mean` an error on a `tensor[?x?]` but `row_sum` is not?

    ??? note "Answer"
        A mean is a sum divided by a count, and the front end bakes the count into the program as a constant. With a `?` size the count does not exist until run time, so there is no constant to divide by. A sum needs no count, so it works for any size.

8. The first mutation run left "a size-1 left operand is not broadcast" uncaught. What does that tell you about the tests, and what was done?

    ??? note "Answer"
        It showed that no test exercised the branch of the broadcast rule where the *left* operand is the one that grows: every example wrote the small operand on the right, so the branch could be deleted with no test noticing. An example with the small operand on the left (including a non-commutative operator, so order matters) and a matching check were added, and the same mutation now fails a test.

9. In the PTX, the reduction's accumulate kernel has three `add.rn.f64` instructions in a row for a 2x3 input. What are they?

    ??? note "Answer"
        They are the three iterations of the inner loop over the columns, unrolled because the column count (3) is a constant. Each GPU thread handles one row and adds that row's three elements into the output cell in order. The row loop was made parallel (one thread per row); the reduction loop was left sequential, because parallelizing a loop that accumulates into one cell would be a race.

10. `relu` is lowered with a NaN-propagating maximum. What is the observable difference from a maximum that ignores NaN?

    ??? note "Answer"
        With a NaN input, a propagating maximum returns NaN, so the problem stays visible in the output, while a NaN-ignoring maximum would return 0 and hide it. This chapter chose propagation (and the GPU's `max.NaN`). No test feeds a NaN to relu, so that behavior is by design and by the instruction's definition, not something the tests demonstrate.
