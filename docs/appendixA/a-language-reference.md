# Appendix A. Mountain Goat Language Reference

![Mountain goats on the mountain drawn as a blueprint](../assets/goats/appx-a.svg){ style="display:block;margin:0 auto;max-width:100%;height:auto;border-radius:6px" }

This appendix is the whole language on one page, in the order a reference is read: what a program is made of, the grammar, the types, every operator and function with its shape rule, and the errors the front end gives. The *Language Tour* page teaches the same material by example; this page is for looking things up. The grammar and the lists of built-in functions come from the front end's own header (`docs/part44/code/mgfront.py`); every snippet in the last section was run through the real compiler, and `appendixA/code/verify_reference.py` fails if any result differs from what is stated here.

!!! tip "Compile and run"
    ```sh
    cd docs/part44/code && ./build.sh        # once: builds mg-opt (needs mlir-18-tools, libmlir-18-dev, cmake)
    cd ../../appendixA/code
    ./verify_reference.py                    # runs all 27 snippets through the compiler and compares (about 1 minute)
    ../../part44/code/mgc run my_program.mg  # compile and run one of your own programs
    ```

## 1. What a program is

A program is a list of lines. Each line is a **comment** (starts with `#`, runs to the end of the line, and may follow a statement on the same line), blank, or one **statement**:

| statement | meaning |
|---|---|
| `let NAME = expr` | give a value a name; a later `let` of the same name replaces it |
| `print expr` | print a matrix (a scalar alone cannot be printed: it has no shape) |
| `def NAME(p: tensor[RxC], ...) = expr` | define a function of tensors; its parameter shapes are checked at **every call** |

There is no loop, no conditional, no indexing, no string, no assignment to part of a value. Computation is built from whole-matrix operations (that is the point of the language: the compiler can see the shapes). One statement fits on one line.

## 2. Grammar

```text
program := (def | stmt)*
def     := 'def' NAME '(' [NAME ':' type (',' NAME ':' type)*] ')' '=' expr
stmt    := 'let' NAME '=' expr | 'print' expr
type    := 'tensor' '[' dim 'x' dim ']'        dim := INT | '?'
expr    := product (('+' | '-') product)*
product := unary (('*' | '/' | '@') unary)*    unary := '-' unary | term
term    := NAME | NUMBER | matrix | 'transpose' '(' expr ')' | NAME '(' expr (',' expr)* ')' | '(' expr ')'
matrix  := '[' row (',' row)* ']'              row := '[' NUM (',' NUM)* ']'
```

Numbers are written as digits with an optional fraction and an optional exponent (`3`, `0.5`, `1e-05`); a minus sign in front is the unary operator. Names are letters, digits and underscores, not starting with a digit.

## 3. Values and types

Every matrix is two-dimensional and holds 64-bit floating-point numbers (`f64`). A **matrix literal** is a list of equal-length rows: `[[1, 2, 3], [4, 5, 6]]` is a 2x3 matrix. A **scalar** is a number known when the program is compiled. It combines with a matrix elementwise and can be bound with `let` (`let s = 2` then `a * s`), but it has no shape, so it cannot be printed on its own.

A **function parameter's type** is `tensor[RxC]`, where each of R and C is an integer or `?`. A `?` is a **dynamic** dimension: the function is compiled once and works for any size there, (A function that averages along a dynamic axis is refused: `col_mean needs a static size along the averaged axis, not '?'`.)

Tensors of **other ranks** exist only through `reshape`, `permute` and `contract` (Chapter 28): a value of rank other than 2 can be reshaped, permuted, contracted, bound with `let` or printed, and nothing else; every other operation needs a matrix.

## 4. Operators

From tightest to loosest binding; operators on the same line group left to right:

| operator | meaning | shape rule |
|---|---|---|
| `-` (unary) | negate | same shape |
| `*`  `/`  `@` | `*` and `/` elementwise (`*` is the Hadamard product, not the matrix product); `@` matrix product | `*` `/`: same shape or a size-1 stretch; `@`: `RxK` and `KxC` give `RxC` |
| `+`  `-` | elementwise add and subtract | same shape or a size-1 stretch |

**The stretch rule.** In `+ - * /`, a dimension of size 1 is stretched to meet the other operand's size, in each dimension separately: `RxC` with `1xC`, `Rx1` or `1x1` gives `RxC`. A dimension that is neither equal nor 1 is an error. `@` never stretches: the inner sizes must be equal, and then they vanish. One consequence: `2 * a @ b` is `(2 * a) @ b`, since `*` and `@` have the same precedence and group left to right.

## 5. Built-in functions

| function | result | shape |
|---|---|---|
| `transpose(a)` | rows and columns swapped | `RxC` becomes `CxR` |
| `relu(a)` | `max(0, x)` for each element | same |
| `exp(a)`, `sqrt(a)`, `log(a)` | elementwise `e^x`, square root, natural logarithm | same |
| `ge(a, b)` | 1.0 where `a >= b`, 0.0 elsewhere (a comparison; the stretch rule applies) | broadcast of the two |
| `row_sum(a)`, `row_max(a)`, `row_mean(a)` | one value per **row** | `RxC` becomes `Rx1` |
| `col_sum(a)`, `col_max(a)`, `col_mean(a)` | one value per **column** | `RxC` becomes `1xC` |
| `reshape(a, d0, d1, ...)` | the same elements, viewed in another shape with the same number of elements | any rank |
| `permute(a, p0, p1, ...)` | reorders the axes: result axis *i* is input axis *p<sub>i</sub>* | any rank |
| `contract(a, (i, ...), b, (k, ...))` | sums products over the paired axes; the result's axes are *a*'s free axes, then *b*'s | any rank |

The mean functions need the size of the averaged axis known at compile time (a `?` there is an error). The reductions "squash" one axis; to subtract a column's mean from every element of the column write `data - col_mean(data)`, which relies on the stretch rule.

## 6. Running a program

`mgc` is the compiler driver (Chapter 20 explains each stage it runs, and Appendix E lists its options):

| command | does |
|---|---|
| `mgc run prog.mg` | compile to a native executable and run it; `print` writes the matrices |
| `mgc mlir prog.mg` | show the MLIR the front end produces (Appendix B introduces it) |
| `mgc build prog.mg -o exe` | compile to an executable without running it |
| `mgc lib prog.mg` | compile the `def`s to `prog.o` plus a C++ header `prog.h` (no `main`), for linking into your own program (Chapter 20 introduces it) |
| `mgc ptx prog.mg` | compile to GPU code (PTX); nothing is launched |

## 7. Every snippet, run for real

Each block below is a program, followed by what the compiler printed (a matrix, or an error message with the line number removed). Numbers print with up to six significant digits. These are the outputs of `verify_reference.py`; its exit status is 0 only if all 27 match the results stated in the script.

```text
--8<-- "docs/appendixA/code/reference_out.txt"
```

## 8. What is deliberately not in the language

No loops, conditionals, recursion, indexing, slicing, strings, user-defined types or modules; one numeric type (`f64`); no way to read input at run time (data is written into the program as literals). Mountain Goat is small on purpose: the book is about the compiler, and each missing feature is something a real compiler would need a section of its own to handle. Where the book needed more (training loops, attention, gradients) it wrote them as **unrolled straight-line programs** or as generated programs (Chapters 33 to 36, 45), which is why some programs in this book are hundreds of lines long.
