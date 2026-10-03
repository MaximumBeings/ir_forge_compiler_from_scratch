# Appendix B. Introduction to MLIR

Chapters 1 to 46 use MLIR constantly and explain each piece where it first appears. This appendix collects the ideas in one place, in the order you would learn them if you started here: what MLIR is, what one operation looks like, what a dialect and a pass are, and then one real program followed down through every stage the compiler runs. Every listing was produced by running the tool named above it (LLVM 18's `mlir-opt-18` and `mlir-translate-18`, and this book's own `mg-opt`).

!!! tip "Compile and run"
    ```sh
    cd docs/part44/code && ./build.sh          # once: builds mg-opt (needs mlir-18-tools, libmlir-18-dev, cmake)
    cd ../../appendixB/code
    ./run_stages.sh                            # regenerates every file this appendix shows (a few seconds)
    ```

## B.1 What MLIR is

**MLIR** (Multi-Level Intermediate Representation) is a framework for writing compilers whose intermediate code comes in several *levels* at once. A conventional compiler has one IR (say, LLVM IR) and every optimisation has to be expressed in it. MLIR lets a compiler keep a program at a high level (here: matrices and whole-matrix operations) for as long as that helps, and lower it step by step to loops, then to pointers and basic blocks, then to LLVM IR, with each level having the operations that suit it. The compiler in this book is exactly that: `mg` (matrices) → `affine` (loops over memory) → `llvm` (pointers and blocks) → LLVM IR text → machine code. Chapter 1 argues why this is worth doing; this appendix shows what it looks like.

## B.2 One operation, two ways of printing it

Everything in MLIR is an **operation**. A small function, written by hand (`add_zero.mlir`):

```text
--8<-- "docs/appendixB/code/add_zero.mlir"
```

`mlir-opt-18 add_zero.mlir` reads it and prints it back in its usual ("pretty") form. `--mlir-print-op-generic` prints the *same program* in the generic form that every operation can be written in:

```text
--8<-- "docs/appendixB/code/6_pretty.mlir"
```

```text
--8<-- "docs/appendixB/code/7_generic.mlir"
```

Reading the generic form tells you what an operation is made of:

| part | in `%1 = "arith.addi"(%arg0, %0) <{overflowFlags = ...}> : (i32, i32) -> i32` |
|---|---|
| **name** | `arith.addi`: the dialect (`arith`) and the operation (`addi`) |
| **operands** | `%arg0` and `%0`, the values it uses |
| **result** | `%1`, a new value it defines |
| **attributes** | `<{overflowFlags = ...}>`: constant information attached to the operation itself (not computed at run time) |
| **type signature** | `(i32, i32) -> i32` |
| **regions** | the `({ ... })` blocks: an operation can contain other operations. `func.func` contains a **region** with one **block** (`^bb0`) whose arguments are the function's parameters |

Three properties to remember:

- **SSA.** Each value (`%0`, `%1`, ...) is defined exactly once and never changed. "Updating" a variable means defining a new value.
- **Everything is typed.** `i32` is a 32-bit integer, `f64` a 64-bit float, `tensor<1x3xf64>` a value-semantics array, `memref<1x3xf64>` a reference to memory holding one.
- **The pretty form is only a notation.** The operation behind `arith.addi %a, %b : i32` is the generic one above. When you see a custom dialect's printed form (this book's `mg.add`), it is the same structure with a nicer spelling.

## B.3 Dialects

A **dialect** is a named group of operations, types and attributes: `arith` (integer and floating-point arithmetic), `func` (functions and calls), `scf` (structured loops and conditionals), `affine` (loops whose bounds and indexing are affine expressions, which makes them analysable), `memref` (memory buffers), `cf` (branches between blocks), `math` (`exp`, `sqrt`, ...), `llvm` (a one-to-one image of LLVM IR), `gpu` and `nvvm` (GPU kernels and NVIDIA's flavour of LLVM). **A program may mix dialects**, and lowering is the process of replacing operations of a higher dialect by operations of lower ones until only `llvm` is left. The book defines one dialect of its own, `mg`, with operations such as `mg.add`, `mg.matmul`, `mg.reduce`, `mg.print` (Chapter 2 builds the dialect from scratch).

## B.4 Passes

A **pass** is a program transformation: it takes a module and returns a module. Some *optimise* (stay in the same dialect, make the code better) and some *lower* (change dialect). `canonicalize` is the standard clean-up pass; run on `add_zero.mlir` it recognises that adding zero changes nothing:

```text
--8<-- "docs/appendixB/code/8_canonicalized.mlir"
```

(`mlir-opt-18 add_zero.mlir --canonicalize`: the constant and the addition are gone, and the function returns its argument.) A **pipeline** is a list of passes run in order; the command line of `mlir-opt-18` or `mg-opt` is exactly that list. `mg-opt` is this book's copy of `mlir-opt` with the book's own passes registered (`--convert-mg-to-affine`, `--mg-set-fastmath`, `--mg-outline-loops`, ...; Appendix E lists them).

## B.5 One program through every stage

The program (`tiny.mg`):

```text
--8<-- "docs/appendixB/code/tiny.mg"
```

**Stage 1, the front end** (`mgc mlir tiny.mg`, 13 lines). Mountain Goat text becomes `mg`-dialect MLIR. Every value is a `tensor`; every operation is a whole-matrix operation:

```text
--8<-- "docs/appendixB/code/1_mg.mlir"
```

**Stage 2, `mg-opt --convert-mg-to-affine`** (58 lines). Tensors become `memref` buffers and each whole-matrix operation becomes loops (`affine.for`) over elements. Here is `scale_add` (the rest of the file is `main`, which fills its constant matrices element by element):

```text
--8<-- "docs/appendixB/code/2_affine.mlir:1:23"
```

Note the regions: each `affine.for` *contains* its body; the loop variable `%arg2` is that region's argument. Nothing about memory layout was visible at stage 1; it is now.

**Stage 3, lowering to the `llvm` dialect** (219 lines, with `--lower-affine`, the book's `--mg-scf-to-cf-reverse`, `--convert-arith-to-llvm`, `--finalize-memref-to-llvm`, `--convert-func-to-llvm`, `--reconcile-unrealized-casts`). Loops become branches between blocks; every `memref` becomes a five-field descriptor (allocated pointer, aligned pointer, offset, sizes, strides: Chapter 1's first self-check question), which is why the file is four times longer than the one before. **Stage 4, `mlir-translate-18 --mlir-to-llvmir`** (162 lines) prints the same program as LLVM IR text, the input of Appendix C. The compiled program prints what Stage 1 promised:

```text
--8<-- "docs/appendixB/code/5_run_out.txt"
```

`[[12, 24, 36]]` is `[[1, 2, 3]] * 2 + [[10, 20, 30]]`.

## B.6 The tools you will meet

| tool | what it does |
|---|---|
| `mlir-opt-18` | reads MLIR, runs the passes named on the command line, prints MLIR |
| `mg-opt` (this book, built in Chapter 44's `build.sh`) | `mlir-opt` plus the book's `mg` dialect and passes |
| `mlir-translate-18` | converts between MLIR (in the `llvm` dialect) and other formats, here LLVM IR text |
| `mgc` (this book) | the driver: runs the front end, `mg-opt`, `mlir-translate-18` and `clang-18` in the right order; `mgc mlir` stops after the front end |

A useful habit from this book: to see what any pass does, run it alone on a small input and read both sides, as this appendix does.

## B.7 Where to go next

Chapter 1 argues for a multi-level IR. Chapter 2 builds the `mg` dialect; Chapter 3 writes a real pass (canonicalization); Chapters 4 and 5 lower step by step to `affine`, `scf` and `llvm` until a Mountain Goat program runs; Chapter 6 adds bufferization; Chapter 7 loop transforms (fusion, tiling, unrolling); Chapter 8 a standalone native executable. Chapter 20 is the full driver. For what the passes do to speed, see Chapters 23, 24 and 44; for compile time, Chapters 38, 39, 42 and 43. Appendix C is the next level down: the LLVM IR that Stage 4 above prints, and the machine code it becomes.
