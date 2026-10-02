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
./run_tour.sh > tour_out.txt                      # run every example on this page
```

`mgc run` needs LLVM 18's MLIR tools (`mlir-opt-18`, `mlir-translate-18`, `clang-18`) installed; see Getting Started. Chapter 20 explains each stage `mgc` runs.

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

## Mistakes the compiler reports

The compiler checks what it can **before** producing any code, and reports the file and line. Each of these is one real example from `docs/tour/code/errors/`:

```text
--8<-- "docs/tour/code/tour_out.txt:111:175"
```

In order: a line that starts with something other than `let`, `print` or `def`; a name that was never declared; adding a 2x3 to a 3x2 (neither differing dimension is 1, so not even broadcasting can fix it); calling a function before it is defined; giving a function the wrong number of arguments; trying to print a scalar; passing a matrix whose shape does not fit the parameter; a zero-size dimension; and a `def` with no expression after the `=`. Every one of these exits with status 1 and produces no program.

What the compiler **cannot** check is a mismatch between two `?` dimensions, since the sizes do not exist until the program runs. That check happens at run time (Chapter 14); see Chapter 20's example 4 and Chapter 21's example 12.

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
