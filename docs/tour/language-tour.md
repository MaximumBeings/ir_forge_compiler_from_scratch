# Mountain Goat: A Short Tour of the Language

This page is a short introduction to the Mountain Goat **language**: what a program looks like, what values and types exist, how to declare things, and what each operator does. It is the page to read first if you have not seen the language before. Chapters 20 and 21 build and extend the compiler for it; this page only describes what you can write.

Everything on this page was run for real. Each example is a file in `docs/tour/code/`, and each output below is what the compiler and the program printed.

## Compile and run

```sh
cd docs/part22/code && ./build.sh      # once: builds the compiler's mg-opt tool
cd ../../tour/code
../../part22/code/mgc run 01_first_program.mg    # compile to a native executable and run it
../../part22/code/mgc mlir 01_first_program.mg   # show the MLIR the front end produces
../../part22/code/mgc ptx  05_dynamic_types.mg   # compile to GPU code (PTX); nothing is launched
./run_tour.sh > tour_out.txt                      # run examples 1-6 and the first nine errors
./run_gallery.sh > gallery_out.txt                # run the gallery (examples 7-16) and three more errors
```

`mgc run` needs LLVM 18's MLIR tools (`mlir-opt-18`, `mlir-translate-18`, `clang-18`) installed; see Getting Started. Chapter 20 explains each stage `mgc` runs.

## The mental model: think in shapes

Before any syntax, one idea carries the whole language: **every value is a rectangle of numbers, and every operation is a rule about rectangles.** An `RxC` matrix has R rows and C columns. If you can say the shape of each line of your program, you can say whether it is legal, and the compiler does exactly that check, before it generates any code.

Four rules cover almost everything you will write:

| Rule | Shapes in | Shape out | Example |
|---|---|---|---|
| **Same shape** (`+ - * /`) | `RxC` and `RxC` | `RxC` | `a + b` adds matching elements |
| **Size 1 stretches** | `RxC` and `1xC` (or `Rx1`, `1x1`) | `RxC` | `data - col_mean(data)` |
| **Inner sizes meet** (`@`) | `RxK` and `KxC` | `RxC` | the K's must match, then vanish |
| **Reductions squash one axis** | `RxC` | `1xC` (`col_`) or `Rx1` (`row_`) | `col_sum(a)` |

Example 7 follows one pair of matrices through all four rules, with the shape written beside every line. It is the same exercise you should do in your head for your own programs:

```text
--8<-- "docs/tour/code/gallery_out.txt:1:23"
```

Read the comments beside each `print`: `(2x3) @ (3x4)` gives `2x4` (the two 3s meet and vanish); `transpose` swaps the two sizes; `col_sum` leaves one total per column (`1x4`); `row_sum` leaves one per row (`2x1`). The printed `sizes = [...]` line is the shape you predicted. When the prediction and the output disagree, you have found a misunderstanding, which is the cheapest time to find it.

### Maths on paper, Mountain Goat on the screen

| You would write | Mountain Goat | Shape rule |
|---|---|---|
| A + B | `a + b` | same shape (or a size-1 stretch) |
| A ∘ B (Hadamard, elementwise) | `a * b` | same shape |
| A B (matrix product) | `a @ b` | inner sizes meet |
| Aᵀ | `transpose(a)` | `RxC` becomes `CxR` |
| −A | `-a` | same shape |
| 2A + 1 | `a * 2 + 1` | scalars are numbers known when compiling |
| Σ over rows, per column | `col_sum(a)` | `RxC` becomes `1xC` |
| Σ over columns, per row | `row_sum(a)` | `RxC` becomes `Rx1` |
| mean of each column | `col_mean(a)` | `1xC`; needs a known row count |
| max(0, x) | `relu(a)` | same shape |
| f(x) = W x + b | `def f(x: tensor[2x1], w: tensor[2x2], b: tensor[2x1]) = w @ x + b` | checked at every call |

The two most common slips are in the first rows: `*` is **not** the matrix product (that is `@`), and a `?` dimension never stretches. Both have worked examples below.

## What a program looks like

A Mountain Goat program is a file ending in `.mg` with **one statement per line**. A `#` starts a comment that runs to the end of the line. Blank lines are ignored. There are three kinds of statement: `let`, `print` and `def`.

```text
--8<-- "docs/tour/code/tour_out.txt:1:10"
```

The first line is a comment. `let m = ...` **declares** a name `m` and gives it a value: a two-by-three matrix. `print m` shows it. The output is MLIR's own runtime printer, not something Mountain Goat designed: `sizes = [2, 3]` is the matrix shape, `strides` says how the data is laid out in memory, and the numbers follow.

## Values and types

Mountain Goat has exactly **one kind of value that can be printed or passed around: a two-dimensional matrix of 64-bit floating-point numbers** (`f64`, the same as C's `double`). There are no integers, strings, booleans, lists or records. Every other piece of the language exists to build, combine or name matrices.

The **type** of a matrix is its shape. You write a type as `tensor[R x C]` where `R` is the number of rows and `C` the number of columns, with no spaces: `tensor[2x3]` is a matrix of two rows and three columns. Types appear only in one place, the parameters of a `def` (below); everywhere else the compiler works the type out for you.

Each dimension is either:

- **a positive whole number**, a **static** dimension known when the program is compiled: `tensor[2x3]`;
- **`?`**, a **dynamic** dimension known only when the program runs: `tensor[?x3]` is "any number of rows, exactly 3 columns", and `tensor[?x?]` is "any shape at all".

A **tensor** is the general word for an array of numbers with any number of dimensions; Mountain Goat only has the two-dimensional kind (a matrix), but keeps the word in the type because that is what the compiler's internal form calls it.

There is one more kind of value, which cannot be printed: the **scalar**, a plain number with no shape, like `4` or `0.5`. A scalar exists only to combine with a matrix (`m * 4`); it is known when the program is compiled, so there is nothing to compute at run time.

## Literals

A **matrix literal** is rows in brackets inside an outer pair of brackets: `[[1, 2, 3], [4, 5, 6]]` is a 2x3 matrix. All rows must have the same length. Numbers may be whole (`2`), decimal (`1.5`), negative (`-2`) or scientific (`3e2`, which is 300).

```text
--8<-- "docs/tour/code/tour_out.txt:11:30"
```

`a` is 1x3 and `b` is 3x1: the shape is simply how the literal is bracketed. `let k = 4` declares a scalar. `a * k` multiplies every element of `a` by 4, so `1.5, -2, 300` becomes `6, -8, 1200`.

## Declaring names with `let`

`let name = expression` gives a name to the value of an expression. The name can then be used in later lines. There are no variables that change: a `let` does not modify anything. A later `let` of the **same name** declares a new binding that replaces the old one from that point on; the right-hand side of the new `let` still sees the old value.

```text
--8<-- "docs/tour/code/tour_out.txt:31:41"
```

Start with `[[1, 2]]`; the second line makes `[[10, 20]]` (using the first `a`); the third makes `[[11, 21]]`. The output is `11, 21`.

A `let` can bind a scalar too (`let k = 2 + 3 * 4` is the scalar 14, computed by the compiler).

## Declaring functions with `def`

`def name(parameters) = expression` declares a function. Each parameter has a name and a type, written `name: tensor[RxC]`. The **body is a single expression**: there are no statements inside a function, so no `let` and no `print` in a body. The function's **result type is worked out** from the body; you do not write it. A function is used by calling it, `name(arguments)`, anywhere an expression can appear.

```text
--8<-- "docs/tour/code/tour_out.txt:42:52"
```

Two rules to know. A function may only call functions **defined above it** (so there is no recursion and no forward reference; the error for breaking this is shown below). And the arguments of a call must fit the parameter types: a matrix of known shape fits a parameter with the same static shape, or a `?`.

## Dynamic dimensions: one function, many shapes

A parameter type with `?` makes the function work for many shapes. The compiler produces **one** compiled function, and the shapes are looked at when it runs.

```text
--8<-- "docs/tour/code/tour_out.txt:53:71"
```

`twice` is called with a 1x2 matrix and then with a 3x1 matrix. `row_sums` accepts any number of rows but exactly 3 columns, and multiplies by a column of ones, so it adds up each row: `1+2+3 = 6` and `4+5+6 = 15`.

When a dimension is `?`, a mismatch cannot be seen while compiling. If two `?` dimensions turn out different at run time, the program **stops with an error message on standard error** (Chapters 14 and 19); it does not print a wrong answer.

## Expressions and operators

An **expression** computes a value: a name, a literal, a function call, `transpose(e)`, a parenthesized expression, or two expressions joined by an operator.

| Operator | Meaning | Shape rule |
|---|---|---|
| `a + b`, `a - b` | elementwise add, subtract | same shape (or `?` that agree at run time) |
| `a * b` | elementwise product (the **Hadamard** product) | same shape |
| `a / b` | elementwise division | same shape |
| `a @ b` | **matrix product** | `a` is m by k, `b` is k by n, result is m by n |
| `transpose(a)` | rows become columns | m by n becomes n by m |
| `-a` | negate every element | same shape |
| matrix `op` scalar, scalar `op` matrix | combine every element with the number (`+ - * /`) | same shape as the matrix |
| `relu(a)` | `max(x, 0)` for every element | same shape |
| `row_sum(a)`, `row_max(a)`, `row_mean(a)` | one value per **row** | m by n gives m by 1 |
| `col_sum(a)`, `col_max(a)`, `col_mean(a)` | one value per **column** | m by n gives 1 by n |

**Broadcasting.** For `+ - * /`, if two shapes differ but each pair of dimensions is equal or has a **static 1**, the size-1 dimension is repeated to fit: `[[1, 2, 3], [4, 5, 6]] + [[10, 20, 30]]` adds the row to both rows. A `?` dimension is never broadcast, and `row_mean`/`col_mean` need a static size along the averaged axis. Chapter 22 explains all of it.

From tightest to loosest binding: unary `-`; then `*`, `/` and `@` (left to right); then `+` and `-` (left to right). Parentheses override. So `a + b * c` means `a + (b * c)`.

```text
--8<-- "docs/tour/code/tour_out.txt:72:110"
```

With `a = [[1, 2], [3, 4]]` and `b = [[10, 20], [30, 40]]` the eight outputs are, in order: `a + b`, `b - a`, `a * b` (elementwise: `10, 40, 90, 160`), `b / a`, `a @ b` (matrix product: `70, 100, 150, 220`), `transpose(a)`, `-a`, and `a * 2 + 1`. Compare the third and fifth: same inputs, different operators, different answers.

## A gallery of small programs

The examples above show one construct at a time. These show constructs **working together** on problems you might recognise. Each is a complete file in `docs/tour/code/`; the output is what `mgc run` printed (`base@ = 0x…` replaces a memory address that changes from run to run). Run them all with `./run_gallery.sh > gallery_out.txt`. For each one, try to predict the output **before** reading it.

### 8. Statistics of a table without loops

Rows are samples and columns are measurements. `col_mean` gives a `1x2`; subtracting it from the `4x2` data stretches it down every row; squaring (`*` with itself) and averaging gives the variance of each column.

```text
--8<-- "docs/tour/code/gallery_out.txt:25:43"
```

The means are 2.5 and 25; the centered data has columns that sum to zero; the variances are 1.25 and 125 (the second column is ten times larger, so its variance is a hundred times larger).

### 9. A polynomial at many points, with one product

Row *i* of the Vandermonde matrix is `[1, x, x²]` for the *i*-th point, so multiplying by the coefficient column evaluates 1 + 2x + 3x² at all three points at once.

```text
--8<-- "docs/tour/code/gallery_out.txt:45:56"
```

Check one by hand: at x = 3, 1 + 6 + 27 = 34.

### 10. Rotating points

Each column of `p` is a point. The matrix `[[0, -1], [1, 0]]` turns every point a quarter turn; applying it twice negates everything.

```text
--8<-- "docs/tour/code/gallery_out.txt:58:75"
```

Look at the third result: `-0`. That is **negative zero**. It compares equal to `0`; floating-point arithmetic keeps the sign of a zero, and negating `0` produces `-0`. Nothing is wrong: it is how IEEE floating point works, and `-0 == 0` is true. (Whether a given zero prints as `0` or `-0` depends on the sign of the operands that produced it, so do not rely on it.)

### 11. A Markov chain

`today` is a `1x2` row of probabilities and `t` is the transition matrix. `today @ t` is tomorrow; squaring `t` three times gives eight steps with three products instead of seven.

```text
--8<-- "docs/tour/code/gallery_out.txt:77:94"
```

The long-run answer is 5/6 sunny, 1/6 rainy (0.8333…, 0.1667…). After eight steps we are at `0.833443`: the distance from 5/6 shrinks by a factor of 0.4 each day, and 0.4⁸ ≈ 0.00066.

### 12. Counting walks in a graph

Entry `[i][j]` of the adjacency matrix `a` is 1 when there is an edge from *i* to *j*. Matrix powers count walks: `a @ a` counts the two-step ones.

```text
--8<-- "docs/tour/code/gallery_out.txt:96:113"
```

In the first result, `[0][3]` is 2: node 0 reaches node 3 in two steps by two different routes (0→1→3 and 0→2→3).

### 13. Blurring an image

Each row of the image is a row of pixels; the blur matrix replaces every pixel with a weighted average of itself and its two neighbours.

```text
--8<-- "docs/tour/code/gallery_out.txt:115:125"
```

The sharp `9` in the middle of the first row spreads into `2.25, 4.5, 2.25`; the total brightness of a row is preserved (9 before, 9 after).

### 14. A function applied twice

`affine` takes a point, a matrix and a shift. The parameter types fix the shapes, so a call with a wrong-shaped argument is rejected at compile time (example 7 in the error list above).

```text
--8<-- "docs/tour/code/gallery_out.txt:127:142"
```

### 15. Any number of samples (and how to add a bias)

`?` in the row count means "any batch size", so `scale` compiles once and serves a batch of one and a batch of three. Adding a bias to every row needs the bias repeated once per sample, and since a `?` size is never stretched, the program does the repeating with a matrix product: a column of ones (`?x1`) times the `1x2` bias is a `?x2` matrix of copies.

```text
--8<-- "docs/tour/code/gallery_out.txt:144:165"
```

### 16. The `?` gotcha: a program that stops by design

What happens if you skip the ones-column and write `batch @ w + b` with a `1x2` bias `b`? It compiles, because a `?` might turn out to be 1. With one sample the shapes happen to match and the answer is right; with three, the program **aborts with a message**, not a wrong answer:

```text
--8<-- "docs/tour/code/gallery_out.txt:167:178"
```

The first call printed `[[11, 22]]`; the second stopped with `mg.add: operand shapes differ at runtime in dimension 0` and exit status 134 (the shell's code for an abort). This is the run-time check from Chapter 14 working as intended. The "FAIL"-looking ending is the expected result of this example, and the fix is example 15.

## Mistakes the compiler reports

The compiler checks what it can **before** producing any code, and reports the file and line. Each of these is one real example from `docs/tour/code/errors/`:

```text
--8<-- "docs/tour/code/tour_out.txt:111:175"
```

In order: a line that starts with something other than `let`, `print` or `def`; a name that was never declared; adding a 2x3 to a 3x2 (neither differing dimension is 1, so not even broadcasting can fix it); calling a function before it is defined; giving a function the wrong number of arguments; trying to print a scalar; passing a matrix whose shape does not fit the parameter; a zero-size dimension; and a `def` with no expression after the `=`. Every one of these exits with status 1 and produces no program.

What the compiler **cannot** check is a mismatch between two `?` dimensions, since the sizes do not exist until the program runs. That check happens at run time (Chapter 14); see Chapter 20's example 4 and Chapter 21's example 12.

Three more mistakes, all about `*` and `@`, the pair beginners mix up most:

```text
--8<-- "docs/tour/code/gallery_out.txt:180:187"
```

```text
--8<-- "docs/tour/code/gallery_out.txt:189:195"
```

```text
--8<-- "docs/tour/code/gallery_out.txt:197:205"
```

The first is `a * b` on a 2x3 and a 3x2: `*` pairs up matching elements, and these do not match. You probably meant `@`. The second is `a @ a` on a 2x3: the inner sizes are 3 and 2. The third is the usual cure, transposing one side so the inner sizes meet; it is **not** an error (the output is `a` times its own transpose, a 2x2).

## Exercises: predict the shape

Before running anything, say the shape of each expression. Then check with `mgc run`. Let `a` be `2x3`, `b` be `3x4`, `c` be `2x4`.

1. `a @ b`
2. `a @ b + c`
3. `b @ a`
4. `transpose(b) @ transpose(a)`
5. `col_sum(a @ b)`
6. `a * a`
7. `a @ a`
8. `row_mean(a) + a`

??? note "Answers"
    1. `2x4`: the inner 3s meet and vanish.
    2. `2x4`: `a @ b` is `2x4`, the same shape as `c`.
    3. **Error.** `3x4` @ `2x3` has inner sizes 4 and 2. The order of `@` matters.
    4. `4x2`: `(3x4)ᵀ` is `4x3`, `(2x3)ᵀ` is `3x2`, and `4x3 @ 3x2` is `4x2`. It is exactly `transpose(a @ b)`, a fact you can confirm with example 7.
    5. `1x4`: one total per column.
    6. `2x3`: elementwise, so the shape is unchanged (it is not a matrix product).
    7. **Error.** Inner sizes 3 and 2, shown in the third error example above.
    8. `2x3`: `row_mean(a)` is `2x1`, and a size-1 column stretches across the three columns.

Next, three small design questions.

**Q1. Why does the compiler reject `a * b` for a 2x3 and a 3x2 instead of quietly doing something sensible?**

??? note "Answer"
    Because there is no single sensible meaning. `*` is defined as "same shape, element by element"; the only stretching allowed is a size of exactly 1. Guessing (say, a matrix product) would hide a bug rather than report it. The error names the shapes so you can see which side to fix.

**Q2. Why does example 16 compile but abort, when example 7's mismatch is rejected before it ever runs?**

??? note "Answer"
    Example 7's dimensions are numbers in the source, so the compiler can compare them. In example 16 the row count of `batch @ w` is `?`, which could be 1 at run time (and would then match the bias). The compiler cannot know, so it lets the program through and the generated code checks the sizes when it runs. Everything the compiler can check statically it does; the rest becomes a run-time check with a message.

**Q3. Why does `ones @ b` work as a stand-in for "repeat `b` once per row"?**

??? note "Answer"
    A `?x1` column of ones times a `1x2` row is `?x2`; entry `[i][j]` is `1 · b[j]`, so every row is a copy of `b`. The matrix product does the repeating, and its shape rule (inner sizes 1 and 1 meet) is satisfied for any number of rows.

## The full grammar

The language's complete grammar is in the header comment of the front end's source, shown here exactly as in `mgfront.py`:

```text
--8<-- "docs/part22/code/mgfront.py:2:18"
```

(`INT`, `NUM` and `NAME` are the usual: digits, numbers, and letters-digits-underscores starting with a letter or underscore.)

## What the language does not have

No integers, strings or booleans; no loops, conditionals or recursion; no indexing into a matrix or reading a single element; no matrices of other ranks (no vectors that are one-dimensional, no three-dimensional arrays); broadcasting only for static size-1 dimensions (a `?` dimension is never broadcast); no variables that change; no input from files or the keyboard; no `let` or `print` inside a function; no way to import another file. These are not oversights to apologize for: the language is the size of the compiler this book builds, and every feature has to be lowered, verified and tested.

## Where each construct goes in the compiler

| You write | The front end emits (Chapters 3, 20, 21, 22) | Lowered by |
|---|---|---|
| `[[1, 2], [3, 4]]` | `mg.constant` | Chapter 4 |
| `a + b`, `a - b`, `a * b`, `a / b` | `mg.add`, `mg.sub`, `mg.mul`, `mg.div` | Chapters 4, 14, 21 |
| `a @ b` | `mg.matmul` | Chapter 21 |
| `transpose(a)` | `mg.transpose` | Chapter 4 |
| `-a` | `mg.neg` | Chapter 21 |
| `a + 3`, `10 - a`, ... | `mg.scalar` | Chapter 21 |
| `relu(a)` | `mg.relu` | Chapter 22 |
| `row_sum(a)`, `col_max(a)`, ... | `mg.reduce` (mean adds a `mg.scalar` divide) | Chapter 22 |
| `a + bias` with a size-1 dimension | `mg.broadcast` then the elementwise op | Chapter 22 |
| `print a` | `mg.print` | Chapter 13 |
| `def f(...) = ...` | a `func.func` | Chapters 4 and 5 |
| a call `f(x)` | `func.call`, with a `tensor.cast` if a static shape meets a `?` | Chapter 20 |
| a `?` dimension | a `?` in the tensor type; a run-time `cf.assert` | Chapters 13, 14, 19 |

## Quick reference

```text
# comment
let name = expr                       declare a matrix or scalar
def f(a: tensor[RxC], ...) = expr     declare a function (R, C: positive integer or ?)
print expr                            print a matrix
[[1, 2], [3, 4]]                      matrix literal      3.5  -2  1e3   scalar literal
+  -   elementwise            *  /   elementwise (or matrix with scalar)
@      matrix product         -a     negate        transpose(a)
```
