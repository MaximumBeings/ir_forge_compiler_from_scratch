# Background: LLVM and MLIR in Twenty Minutes

![Mountain goats on the mountain in sepia](assets/goats/background.svg){ style="display:block;margin:0 auto;max-width:100%;height:auto;border-radius:6px" }

**What you will understand:** just enough about LLVM and MLIR to read the rest of this book. What LLVM IR looks like and why it is written the way it is; what MLIR adds on top (dialects, operations, regions, passes); what "lowering" means; and how a program travels from a high-level description down to a running executable. Every command below was run, and every output is the real output of the Ubuntu LLVM 18.1.3 tools this book uses. This page is a map, not a manual: the book builds the details one chapter at a time, and the "Limits" section says what is left out.

**What you need to know first:** nothing about compilers. You should be able to read a few lines of C.

!!! tip "Compile and run"
    ```sh
    cd docs/background/code
    ./run_background.sh > background_out.txt     # runs every command on this page (needs clang-18, mlir-opt-18, mlir-translate-18)
    ```
    The tools are listed on [Getting Started](getting-started.md). Nothing else needs building.

## The picture: a compiler is a staircase of languages

A compiler does not translate source code to machine code in one jump. It translates through a series of **intermediate representations** (IRs), each a little closer to the machine and a little further from the programmer, and it improves the program at each step. LLVM is a widely used compiler toolkit built around one such IR. MLIR (Multi-Level Intermediate Representation, part of the LLVM project) is a framework for designing *many* IRs and moving between them.

```text
 your language        high-level IR(s)            LLVM IR              machine code
 (Mountain Goat) ---> (the mg dialect, then   --->  (one low-level  ---> (x86-64 here)
                       affine/memref/scf)           language)
        \________________ MLIR ________________/  \__ LLVM __/   \_ clang's backend _/
```

This book builds the left half of that staircase for a tiny matrix language, Mountain Goat, and uses LLVM for everything to the right. Read the rest of this page as a tour of the two halves.

## LLVM IR

### One function, two ways

Here is the smallest useful C function:

```c
--8<-- "docs/background/code/sum.c"
```

`clang-18 -S -emit-llvm -O0 sum.c` asks clang to stop after translating to LLVM IR (`-S -emit-llvm`) and to do no optimization (`-O0`). The lines that matter, with clang's bookkeeping lines removed:

```text
--8<-- "docs/background/code/background_out.txt:7:16"
```

How to read it:

- `define i32 @add(i32 %0, i32 %1)`: a **function** returning a 32-bit integer (`i32`) and taking two. `@` marks a global name. `%` marks a local one. Unnamed values are numbered (`%0`, `%1`, `%2`, ...).
- Every line that makes a value has the form `%name = instruction type operands`. A **value is assigned once and never changed**: this is **SSA** (static single assignment), and it is the single most important property of LLVM IR, because it makes it easy for the compiler to reason about where each value comes from.
- At `-O0` clang is naive: it gives every C variable a slot in memory (`alloca`), stores the arguments there, loads them back, adds, and returns (`add nsw i32` is a signed addition that the compiler may assume does not overflow). That is slow but simple, and it is exactly what the optimizer expects to clean up.
- Types are explicit everywhere (`i32`, `ptr`). There is no implicit conversion.

### Basic blocks, branches, and phi

A function with a loop has several **basic blocks**: straight-line sequences that end in a **branch** (`br`). Here is a loop that adds the numbers 1 to n:

```c
--8<-- "docs/background/code/loop.c"
```

At `-O0`:

```text
--8<-- "docs/background/code/background_out.txt:19:46"
```

The labels `5:`, `9:`, `13:`, `16:` start blocks. The block at `5:` is the loop test (`icmp sle` compares, `br i1 %8, label %9, label %16` jumps to the body or to the exit); the body adds to the memory slot; `13:` increments `i` and jumps back. Every variable lives in memory (`%3` is `total`, `%4` is `i`), because SSA values cannot be reassigned and a loop needs values that change.

LLVM's optimizer turns those memory slots back into values. At `-O1`:

```text
--8<-- "docs/background/code/background_out.txt:49:67"
```

No memory is left. Even more striking, **the loop is gone**: LLVM recognized that adding 1 through n has a closed form (n(n+1)/2) and computed it with a handful of arithmetic instructions (the odd `i33` is a 33-bit integer used so the multiplication cannot overflow). What remains of the control flow is the early exit for `n < 1` and one `phi`.

**`phi`** is how SSA handles "this value depends on which way we got here": `%15 = phi i32 [ 0, %1 ], [ %13, %3 ]` means "0 if we arrived from block `%1`, `%13` if from block `%3`". You do not write `phi` by hand often; you read it as "a variable that gets a different value on different paths".

### You can write it by hand

LLVM IR is a language like any other. This function returns the larger of two integers, and it is compiled and called from C:

```text
--8<-- "docs/background/code/background_out.txt:70:77"
```

(The first block is `handwritten.ll`; the last line is the output of the C program in `main_max.c` linked with it.) `clang-18` accepts `.ll` files just as it accepts `.c` files. This is exactly how every chapter of this book gets its generated code to run: the compiler produces LLVM IR, and `clang-18` finishes the job.

## MLIR

### What MLIR is for

LLVM IR is one fixed language at one level: roughly the level of a processor's instructions. A matrix multiplication, a loop nest, or a GPU kernel have structure that is awkward to see once everything is flattened to blocks and branches, and an optimization such as "tile this loop nest for the cache" is far easier to do *before* flattening. MLIR's idea is to let a project define its own **dialects** (families of operations and types at whatever level it needs) and then **lower** step by step from one dialect to the next, optimizing at the level where each optimization is easiest. LLVM IR itself is one of MLIR's dialects (called `llvm`), the last stop before real LLVM.

### The vocabulary

| Word | What it is | Seen in the example below |
|---|---|---|
| **Operation** | the basic unit: everything is an operation, from `+` to a whole function | `arith.addi`, `func.func`, `scf.for` |
| **Dialect** | a named family of operations, types and attributes; the name before the dot | `arith`, `func`, `scf`, `cf`, `llvm` (and this book's own `mg`) |
| **Value** | the result of an operation, assigned once (SSA, as in LLVM) | `%0`, `%arg1` |
| **Type** | every value has one, written after a colon | `i32`, `index`, `memref<2x3xf64>`, `tensor<2x3xf64>` |
| **Attribute** | constant information attached to an operation | `overflowFlags = #arith.overflow<none>`, `sym_name = "add"` |
| **Region / block** | an operation can contain other operations, grouped in blocks inside regions: this is how a function holds its body and how `scf.for` holds a loop body | the braces after `func.func` and `scf.for` |
| **Pass** | a transformation of the IR, selected by a flag on `mlir-opt-18` | `--canonicalize`, `--convert-scf-to-cf` |
| **Lowering** (conversion) | a pass that rewrites operations of a higher dialect into a lower one | `--convert-arith-to-llvm` |

### The same function in MLIR

```text
--8<-- "docs/background/code/add.mlir"
```

`mlir-opt-18 add.mlir` parses the file, **verifies** it (each operation checks its own rules, and the tool prints nothing and fails if one is broken) and prints it back:

```text
--8<-- "docs/background/code/background_out.txt:80:85"
```

The output wraps the function in a `module` (the top-level container) and gives the argument names `%arg0` and `%arg1`. Everything has the shape `%result = dialect.operation operands : type`. `--mlir-print-op-generic` shows the structure under the friendly syntax: every operation is `"dialect.name"(operands) <{attributes}> : (operand types) -> result types`, and operations nest inside regions:

```text
--8<-- "docs/background/code/background_out.txt:89:95"
```

That generic form is the same for every dialect, which is why one tool (`mlir-opt-18`) can read and transform all of them. The nicer syntax each dialect provides is only a convenience for people.

### A pass: constant folding and common subexpressions

```text
--8<-- "docs/background/code/fold.mlir"
```

`--canonicalize` applies each operation's own simplification rules (including computing constants); `--cse` removes a computation that is written twice. Together:

```text
--8<-- "docs/background/code/background_out.txt:99:104"
```

The whole function became `return 10`, with the sum written once, then twice, then added, all computed by the compiler. This is the kind of improvement a **pass** makes, and this book writes passes of its own.

### A loop, and then lowering it

The loop from the C example, written with MLIR's `scf` (structured control flow) dialect. Notice that the loop is *one operation* with the body inside it, and that the running total travels through `iter_args` and `scf.yield` instead of through memory:

```text
--8<-- "docs/background/code/sum_loop.mlir"
```

```text
--8<-- "docs/background/code/background_out.txt:108:119"
```

(`mlir-opt-18` parses it and prints it back, with names tidied.) Now **lower** it, one step at a time. First `--convert-scf-to-cf`: the structured loop becomes basic blocks and branches, with the values that change (`%1`, `%2`) passed as block arguments, which is MLIR's version of `phi`:

```text
--8<-- "docs/background/code/background_out.txt:123:139"
```

Then the arithmetic and the function itself are converted to the `llvm` dialect (the three flags in the heading; `--reconcile-unrealized-casts` cleans up the glue left between conversions). Notice that `index`, MLIR's pointer-sized integer, became `i64`:

```text
--8<-- "docs/background/code/background_out.txt:143:159"
```

That is now text in MLIR's `llvm` dialect, which is a one-to-one image of real LLVM IR. The last MLIR tool, `mlir-translate-18 --mlir-to-llvmir`, writes it as real LLVM IR text:

```text
--8<-- "docs/background/code/background_out.txt:163:177"
```

Compare it with the `-O1` loop above: here the loop is a literal loop with two `phi`s (the counter `%4` and the total `%5`), because nothing optimized it. Finally `clang-18` compiles that LLVM IR and links it with a C `main` (`main_sum.c`):

```text
--8<-- "docs/background/code/background_out.txt:180:180"
```

(`sum_to(10) = 55` and `sum_to(100) = 5050`, the sums one would compute by hand.) That is a complete journey: **a high-level loop, lowered dialect by dialect, to LLVM IR, to a running program.**

## How this book uses all of this

Every Mountain Goat program travels the same staircase. The driver `mgc` (Chapter 20) runs the stages you have just seen, plus the first one, which is the book's own:

| Stage | Tool | What happens | Where the book builds it |
|---|---|---|---|
| 1 | `mgfront.py` | Mountain Goat source is translated to the **`mg` dialect**, a dialect this book defines: operations such as `mg.matmul`, `mg.add`, `mg.reduce` on tensor values | the dialect: Chapter 2; passes on it: Chapter 3; the front end: Chapters 20 to 22 |
| 2 | `mg-opt` (`--convert-mg-to-affine`) | the `mg` operations are **lowered** to loops over memory (`affine`, `memref`, `arith`), and a size check is added where shapes are not known in advance | Chapters 4 to 6 (lowering and bufferization), 14 (the size check), 21 and 22 (more operations), 24 (the matrix product) |
| 3 | `mg-opt` (`--lower-affine --convert-scf-to-cf ... --convert-func-to-llvm`) | loops and arithmetic are lowered to the **`llvm` dialect**, the same step as the last two you saw above | Chapter 5 (and 19, which reports a failed size check on stderr) |
| 4 | `mlir-translate-18 --mlir-to-llvmir` | the `llvm` dialect becomes real **LLVM IR** | Chapter 1 (the first complete pipeline) |
| 5 | `clang-18` | LLVM IR becomes a native **executable** | Chapter 1, and Chapter 8 (a standalone executable) |

`mgc mlir prog.mg` shows the output of stage 1; setting `MGC_KEEP=dir` keeps every intermediate file, so you can look at each stage of your own program the way this page looked at `sum_to`. The book's own passes (stage 2) are ordinary MLIR passes in C++, and its own dialect is defined in a declarative file (TableGen, see below) from which MLIR generates the C++.

## Glossary

- **SSA** static single assignment: every value is defined once. LLVM IR and MLIR both require it.
- **Basic block** a straight-line run of instructions ending in a branch or a return.
- **`phi` / block argument** the way SSA expresses "this value depends on where control came from".
- **Dialect** a named family of operations, types and attributes (`arith`, `scf`, `llvm`, `mg`).
- **Pass** a transformation of the IR (an optimization or a lowering).
- **Lowering** rewriting a higher-level dialect's operations into a lower-level one's.
- **Module** the top-level container of a file of IR (in both LLVM and MLIR).
- **Verifier** the checks that run on IR so a malformed program is rejected rather than miscompiled.
- **Tensor / memref** MLIR's two ways of describing an array: a tensor is an immutable *value* (like a number), a memref is a *reference to memory* (like a pointer with a shape). This book's `mg` dialect works on tensors, and lowering turns them into memrefs.
- **TableGen / ODS** LLVM's declarative description language. Dialect operations in this book are defined in `.td` files in it, and the C++ classes are generated.

## Self-check questions

Each answer is collapsed; try the question first.

1. What does SSA require, and why does a loop in LLVM IR need `phi`?

    ??? note "Answer"
        SSA requires that every value is assigned exactly once. A loop counter has a different value in each iteration, so it cannot be one value; `phi` says "take this value if we came from before the loop and that one if we came from the end of the body". At `-O0` clang avoids the issue by keeping the variable in memory (`alloca`, `store`, `load`), which is not SSA-restricted; the optimizer then converts memory back into SSA values and `phi`s (example 3).

2. In example 3 the optimizer removed the loop altogether. What does that tell you about when optimizations are done at the LLVM level?

    ??? note "Answer"
        LLVM can recognize patterns in the IR (here an induction variable summed in a loop) and replace them by a closed form, but it has to *recognize* the pattern in the flat blocks-and-branches form. That is the argument for MLIR's higher levels: an optimization that wants to know "this is a matrix product" or "this is a loop nest over a 2-D array" is far easier while that structure still exists, before everything is lowered to branches.

3. What is the difference between a dialect and a pass?

    ??? note "Answer"
        A dialect is a *vocabulary*: a set of operations, types and attributes (`arith.addi`, `scf.for`). A pass is a *transformation*: it rewrites IR, for example constant folding (`--canonicalize`) or lowering one dialect's operations to another's (`--convert-scf-to-cf`). Dialects say what you can write; passes change what you have written.

4. Why do MLIR operations written as `%0 = arith.addi %a, %b : i32` and as `"arith.addi"(%a, %b) : (i32, i32) -> i32` mean the same thing?

    ??? note "Answer"
        The second is MLIR's *generic* form, the same for every operation of every dialect: quoted name, operands, attributes, then a function-style type. The first is the *custom* syntax that the `arith` dialect provides for readability. The tools parse both and treat them as the same operation, which is why `mlir-opt-18` can transform dialects it has no special knowledge of.

5. In the lowering example, which step turned `scf.for` into basic blocks, and what replaced the loop-carried value `iter_args`?

    ??? note "Answer"
        `--convert-scf-to-cf` did. The loop-carried values (the counter and the running total) became **block arguments** of the loop-header block (`^bb1(%1: index, %2: index)`), and each branch back to the header passes the new values (`cf.br ^bb1(%5, %4 : index, index)`). Block arguments are MLIR's counterpart to LLVM's `phi`; when `mlir-translate-18` writes LLVM IR they become real `phi` instructions.

6. Which tool translates the `llvm` dialect to LLVM IR, and why is that step so simple compared with the earlier ones?

    ??? note "Answer"
        `mlir-translate-18 --mlir-to-llvmir`. The `llvm` dialect is a one-to-one image of LLVM IR (`llvm.add` is `add`, `llvm.cond_br` is `br i1`), so there is nothing to decide, only text to write in the other format. All the real work, deciding how higher-level operations become instructions, happened in the lowering passes before it.

7. If you wanted to see what `mgc` does to one of your own programs at each stage, how would you?

    ??? note "Answer"
        `mgc mlir prog.mg` prints stage 1's output (the `mg` dialect), and `MGC_KEEP=somedir mgc run prog.mg` keeps every intermediate file: the `mg` dialect, the `affine` form after `--convert-mg-to-affine`, the `llvm` dialect, the `.ll` file, and the executable. Each can be read with the vocabulary from this page.

## Limits and what is not established

- **This is a map, not a manual.** It covers what the rest of the book needs. It does not teach MLIR's pass infrastructure, pattern rewriting, interfaces, or the LLVM backend (instruction selection, register allocation), beyond what chapters use.
- **Examples are tiny.** Each shows a concept; none says anything about how the tools behave on large programs.
- **The optimizer's behavior is shown for one program.** That LLVM replaced a summing loop by its closed form is what `clang-18 -O1` does *here, for this loop*; other versions and other loops may behave differently. Nothing on this page measures speed.
- **The two halves are described, not compared.** The claim that high-level optimizations are easier before lowering is argued from the examples and is the project's stated motivation for MLIR; the book's own performance chapters (23 and 24) are where it measures anything.
- **Documentation:** facts about MLIR's and LLVM's design are as the project documents them (`mlir/docs/` and `llvm/docs/` in the `llvm/llvm-project` repository). The pages themselves were not reachable from this book's authoring environment, so this page rests on what the 18.1.3 tools print rather than on quotations.
- **Platform:** x86-64 Linux, Ubuntu's LLVM 18.1.3. The IR in the outputs includes details (alignment, attributes, `noundef`, `nsw`) that vary between versions.

## Where next

Chapter 1 runs a small structured loop through exactly the pipeline you have just seen and shows the moment its loop structure disappears. Chapter 2 defines the `mg` dialect. If you would rather see the language first, read [the language tour](tour/language-tour.md), which needs none of this page.
