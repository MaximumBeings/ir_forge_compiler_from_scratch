# 20. The Mountain Goat Demo: A Surface Syntax, a Driver, and C++ Calling Compiled Code

<p style="text-align:center"><img src="../assets/goats/ch-20.svg" alt="Mountain goats on the mountain in sepia" style="max-width:100%;height:auto;border-radius:6px"></p>

**What you will understand:** how every earlier chapter fits together by *using* the compiler. You will write Mountain Goat programs in a small text language, compile them to native executables with one command, call compiled Mountain Goat functions from a C++ program, and push a program down the GPU path to PTX. This chapter adds a front end (so there is finally a language to write), a driver (`mgc`) and one small lowering, and it runs ten example programs.

**What you need to know first:** nothing new beyond the earlier chapters' vocabulary: tensors and `mg.add`/`mg.transpose` (Chapters 1 to 5), dynamic shapes and the runtime check (Chapters 13 and 14), the stderr abort (Chapter 19) and the GPU recipe (Chapters 10 and 11). Each section says which chapter it is using.

!!! tip "Compile and run"
    ```sh
    cd docs/part20/code
    ./build.sh                      # builds ./build/mg-opt (Chapter 20's)
    ./mgc run examples/03_dynamic.mg    # compile one example to native code and run it
    ./mgc ptx examples/05_gpu.mg        # compile one example to PTX (not run: no GPU here)
    ./demo.sh > demo_out.txt            # all ten examples; the output on this page is this file
    cpp/run.sh                          # build and run the C++ program
    cd ../part15/code && ./run_lit.sh   # the test suite
    ```
    Every listing and output on this page comes from these commands.


!!! note "Why this page shows FAIL lines, and why that is good"
    Parts of this page come from **negative controls**: the same tests run against an *older* build, or against *deliberately broken* code (a "mutation"). In those runs a **FAIL is the expected, wanted result**: it means a test noticed the problem, which is how we know the tests are worth anything. What would be wrong is the opposite, a deliberately broken build that passes everything. The **baseline** (the unmodified current build) must always show every test passing, and it does. Each script that does this says so in its own header and prints a reminder at the top of its output.

## Primer: what "a compiler driver" is

Compilers are rarely one program. `gcc hello.c` looks like one command, but it runs a preprocessor, a compiler proper, an assembler and a linker, passing files between them. The command you type is the **driver**: it knows the stages, their order and their flags, so you do not have to.

Mountain Goat has had all its stages since Chapter 8, but you had to run them by hand: `mg-opt` for the dialect lowering, `mlir-translate` for LLVM IR, `clang` for the executable, and a hand-written C `main` to call the result. And Mountain Goat programs were written as raw MLIR text (`%0 = mg.add %a, %b : tensor<2x2xf64>, ...`), because the language itself had **no surface syntax**: nothing a person would call "writing Mountain Goat".

A **surface syntax** (or **concrete syntax**) is the text a programmer writes. A **front end** reads it, checks it, and produces the compiler's internal form, here MLIR in the `mg` dialect. This chapter builds both missing pieces: a front end for a small language, and the driver that connects it to every stage the book already built.

## The language

A short, example-driven introduction to the syntax, declarations and types is on its own page: [The Mountain Goat Language: A Short Tour](../tour/language-tour.md). This section is the formal summary.

One statement per line. `#` starts a comment. Every value is a two-dimensional matrix of 64-bit floats, which is exactly what the `mg` dialect can represent.

```text
program := (def | stmt)*
def     := 'def' NAME '(' [NAME ':' type (',' NAME ':' type)*] ')' '=' expr
stmt    := 'let' NAME '=' expr | 'print' expr
type    := 'tensor' '[' dim 'x' dim ']'        dim := INT | '?'
expr    := term ('+' term)*
term    := NAME | matrix | 'transpose' '(' expr ')' | NAME '(' expr (',' expr)* ')' | '(' expr ')'
matrix  := '[' row (',' row)* ']'              row := '[' NUM (',' NUM)* ']'
```

Three things to notice. A `def` defines a function whose whole body is one expression. A parameter type is written `tensor[2x3]` for a fixed shape or `tensor[?x?]` for a **dynamic** shape, where `?` means "known only at run time" (Chapter 13). Statements outside a `def` form the program's `main`.

The language is deliberately tiny. It has no loops, no scalars, no `if`, no way to index a matrix, and the only operations are `+` and `transpose`, because those are the only operations the `mg` dialect has. A bigger language would be a different book.

## The front end, `mgfront.py`

The front end is about 240 lines of Python. It is a hand-written **recursive-descent parser**: one small method per grammar rule, each reading tokens and calling the methods for the rules it contains. It does not build a tree first; it **type-checks as it parses** and writes MLIR text directly, tracking each value's shape (a pair of integers, where `None` means dynamic).

The pieces, in order. The error type and the tokenizer (a regular expression that recognizes numbers, names and punctuation):

```python
--8<-- "docs/part20/code/mgfront.py:16:35"
```

The expression parser is where the language's rules live. Addition checks that the two shapes can agree (an integer against an integer must be equal; anything against `?` is accepted and left to the run-time check), `transpose` swaps the pair, and a call inserts a `tensor.cast` whenever an argument's shape is not exactly the parameter's:

```python
--8<-- "docs/part20/code/mgfront.py:49:126"
```

??? note "The rest of `mgfront.py`: types, the top level, and the C++ header generator (click to expand)"
    ```python
    --8<-- "docs/part20/code/mgfront.py:127:244"
    ```

Mistakes are reported with the file and line, and **before any MLIR exists**, so a user never sees an MLIR verifier message for a typo:

```text
--8<-- "docs/part20/code/demo_out.txt:165:181"
```

The shape check is a convenience, not the safety net. The front end can only catch mismatches it can see; for `?` dimensions the run-time check from Chapter 14 is what protects the program, and Chapter 19's pass makes its message visible.

## One new lowering: `tensor.cast`

Passing a fixed-shape matrix to a function that takes `tensor[?x?]` needs a type change on the way in. MLIR spells that `tensor.cast`: it changes only the *static type* of a value, never its contents. Chapters 13 and 14 never needed it, because their dynamic functions were called from C, where the caller supplies raw memref descriptors, not from Mountain Goat code.

The first attempt failed at once, with MLIR's own message:

```text
error: Dialect `tensor' not found for custom op 'tensor.cast'
note: Registered dialects: affine, arith, bufferization, builtin, cf, func, llvm, memref, mg
```

Two things were missing: `mg-opt` never registered the `tensor` dialect, and `--convert-mg-to-affine` had no pattern for the op. The fix is small. The whole change, against the earlier files:

```diff
--8<-- "docs/part20/code/chapter20.diff"
```

The pattern is the bufferized meaning of the op: a `tensor.cast` between tensor types is a `memref.cast` between the converted memref types. Static-to-dynamic is always legal, so nothing is checked here; a *dynamic-to-static* cast would need a run-time check, and the front end never emits one. To rebuild `mg-opt`:

```sh
--8<-- "docs/part20/code/build.sh"
```

## The driver, `mgc`

```sh
--8<-- "docs/part20/code/mgc"
```

Read it as the book's table of contents in shell. Step 1 is the front end. Step 2 is Chapters 4, 5, 13 and 14 (`--convert-mg-to-affine`, including the run-time shape checks). Step 3 is the standard lowering to the LLVM dialect plus Chapter 19's `--mg-lower-assert-to-stderr`, placed after `--convert-scf-to-cf` for the reason Chapter 19 found. Step 4 is `mlir-translate`. Step 5 is `clang`, linked against MLIR's `libmlir_runner_utils`, which supplies `printMemrefF64`, the function `mg.print` calls (Chapter 13).

A first version of this driver linked `libmlir_c_runner_utils` instead and failed with `undefined reference to '_mlir_ciface_printMemrefF64'`; in LLVM 18 the printing functions live in the other library (`nm -D` shows `printMemrefF64` in `libmlir_runner_utils.so` only). The driver hides the compiler's stderr during the final link, so that failure first showed up as a silent exit status 1; running the clang line by hand showed the cause. That is a driver bug of mine, and it is why the test suite includes a mutation that removes the library.

The stages of one real program, `03_dynamic.mg`, with the size of each artifact:

```text
--8<-- "docs/part20/code/show/stage_sizes.txt"
```

The front end's 21 lines become 363 lines of LLVM dialect. Nothing in those lines is a surprise if you have read the earlier chapters; the point of `show.sh` is that every intermediate file is kept if you ask (`MGC_KEEP=dir`). The front end's output for this program:

```mlir
--8<-- "docs/part20/code/show/1_front_end.mlir"
```

## Ten examples

Each example is a file in `docs/part20/code/examples/`, shown with its real output by `demo.sh`. Memref base addresses (the `0x…`) change from run to run and are masked below; everything else is exactly what the program printed.

### 1 and 2. Constants, printing, add and transpose (static shapes)

```text
--8<-- "docs/part20/code/demo_out.txt:1:28"
```

`mg.constant` becomes stores into an allocation; `mg.add` and `mg.transpose` become loops (Chapter 4); `mg.print` becomes a call to `printMemrefF64`. The `sizes` and `strides` fields show the layout: a 2x3 matrix has strides `[3, 1]`, so element `(i, j)` is at offset `3i + j`.

### 3 and 9. Dynamic shapes: one function, many sizes

```text
--8<-- "docs/part20/code/demo_out.txt:29:42"
```

The function `addt` is compiled **once**. The first call passes 2x3 matrices and gets a 3x2 result; the second passes 3x1 matrices and gets 1x3. Example 9 does the same with a row vector (1x4) and a column vector (4x1) through one function:

```text
--8<-- "docs/part20/code/demo_out.txt:99:113"
```

### 4 and 10. When shapes do not match at run time

```text
--8<-- "docs/part20/code/demo_out.txt:42:51"
```

The front end accepted this program: both arguments are fitted to `tensor[?x?]`. The mismatch (2x3 against 3x2) exists only at run time. The message appears on **stderr**, the process dies by `SIGABRT` (exit status 134), and nothing else is printed. That message is Chapter 19's contribution; with the default lowering from Chapter 14 it would have been lost when stdout is not a terminal.

Example 10 is the mixed case: one parameter has a dynamic row count, the other is exactly `3x2`. The first call agrees and prints; the second passes a 2x2 for `a`, and the check fires on dimension 0, **after the first result has already been printed**:

```text
--8<-- "docs/part20/code/demo_out.txt:114:128"
```

### 6, 7 and 8. Composition

```text
--8<-- "docs/part20/code/demo_out.txt:52:98"
```

Example 6 transposes twice and returns to the original 2x3 shape. Example 7 shows that `+` is left-associative and that `transpose` can wrap any expression. Example 8 defines `double` and builds `quad` out of it: functions calling functions, with fixed shapes checked entirely by the front end.

### 5. The GPU path, compile-only

```text
--8<-- "docs/part20/code/demo_out.txt:129:164"
```

`mgc ptx` runs Chapter 10's recipe on the program (`affine-parallelize`, `gpu-kernel-outlining`, `convert-gpu-to-nvvm`, `gpu-module-to-binary`) and prints the PTX. The example uses a `def` with parameters on purpose: the first draft used `let` constants, and the whole program was constant-folded into stores of the precomputed answer, so there was no loop and **no kernel at all**. (The first symptom was Chapter 10's decoder crashing on a missing `assembly` field.)

The kernel takes 23 parameters because each matrix argument expands to a 7-field memref descriptor (Chapter 10); the PTX is the real output of the real pipeline. **Nothing was launched.** This machine has no GPU and no CUDA driver, and the PTX was never assembled with `ptxas`.

## Using it from C++

A compiler is more useful when other programs can call what it compiled. `mgc lib` compiles only the `def`s (no `main`) to an object file and generates a C++ header that wraps the compiled functions. The Mountain Goat source:

```text
--8<-- "docs/part20/code/cpp/kernels.mg"
```

The generated header, `kernels_generated.h`, has three parts. A `mg::Matrix` class that owns a row-major `std::vector<double>`; a table of `extern "C"` declarations using the memref calling convention Chapter 8 introduced (each matrix argument is seven scalars: two pointers, an offset, two sizes and two strides); and one inline C++ function per `def`, which packs the descriptor, calls the compiled code, copies the result out through the strides, and `free`s the buffer the compiled code allocated:

??? note "The generated `kernels_generated.h` (click to expand)"
    ```cpp
    --8<-- "docs/part20/code/cpp/kernels_generated.h"
    ```

An ordinary C++ program that uses it:

```cpp
--8<-- "docs/part20/code/cpp/app.cpp"
```

Built and run by `run.sh`:

```sh
--8<-- "docs/part20/code/cpp/run.sh"
```

```text
--8<-- "docs/part20/code/cpp/run_out.txt"
```

Two kinds of shape error appear at two different layers. `rot` was declared `tensor[2x3]`, so the **generated C++ wrapper** checks the shape and throws `std::invalid_argument` before the compiled code runs; the program catches it and continues. `add` was declared `tensor[?x?]`, so a mismatch reaches the **compiled code's own run-time check**, which writes its message to stderr and aborts the whole process; C++ cannot catch an abort. That asymmetry is a real property of this design, not a bug to hide: a compiled function can only report a failed check the way Chapter 19's pass makes it report one.

## What about CUDA?

Mountain Goat's GPU path ends at PTX, and PTX is exactly what a CUDA program loads. A C++ host program would load the PTX with the CUDA driver API (`cuModuleLoadData`) and launch the kernel with `cuLaunchKernel`, passing the 23 kernel parameters in the order Chapter 10 decoded. This chapter does **not** do that, for a plain reason: there is no GPU and no CUDA driver in this environment, so any such host program could be neither built against `cuda.h` nor run, and the book does not print code it never executed. What is done and tested is everything up to the PTX (example 5, and Chapters 10, 11 and 16), and Chapter 11's CPU stub runtime checks the host-side glue. Running the kernel on a real GPU is open work, listed under the limits.

## Tests

Eight new `lit` tests (suite: 60), in `test/frontend/`. They run the real examples from `part20/code/examples/` instead of copies, so the book and the tests cannot drift apart.

| Test | What it checks |
|---|---|
| `hello-and-static` | examples 1 and 2 compile, run, and print the right matrices |
| `dynamic-runs` | examples 3 and 9: one compiled function, several sizes |
| `more-examples` | examples 6, 7 and 8 |
| `runtime-mismatch-aborts` | examples 4 and 10: abort with the message **on stderr** (and example 10's first result still printed) |
| `front-end-errors` | both error files: the exact `file:line: error:` text, and no MLIR emitted |
| `emit-mlir` | the front end's output for example 3, including the `tensor.cast` |
| `ptx-from-source` | example 5 yields an `add_kernel` entry with loads, `add.rn.f64`, store |
| `cpp-interop` | the C++ program builds with `-Wall -Werror`, runs, and the mismatch aborts with the message |

To check that these tests can fail, `prove_tests_can_fail.sh` runs them against the Chapter 19 build (which has no `tensor.cast` lowering) and against four deliberately broken copies of the front end and driver:

```sh
--8<-- "docs/part20/code/prove_tests_can_fail.sh"
```

```text
--8<-- "docs/part20/code/prove_tests_can_fail_out.txt"
```

Every one of the five breakages makes at least one test fail, and the baseline passes before and after (the script restores the files it mutates). The full suite passes against the new build:

```text
--8<-- "docs/part15/code/run_out_60.txt"
```

## Limits and what is not established

- **The language is tiny.** Matrices of `f64`, rank 2, `+` and `transpose`. No loops, scalars, conditionals, element access, or other element types.
- **The front end is a convenience, not a security boundary.** It catches static shape mismatches; dynamic ones are caught only at run time, by an abort.
- **A matrix literal's numbers are parsed as written**; there is no check for overflow or `nan`.
- **Function names become global C symbols.** A `def` named `exp` or `free` would collide with the C library. The front end does not check.
- **C++ side:** the generated wrapper copies matrices in and out on every call, which is simple and correct but not fast. Nothing here measures performance, and no speed claim is made. A failed dynamic check aborts the process and cannot be caught.
- **GPU:** PTX was produced and inspected but never assembled with `ptxas`, never loaded by a driver, never launched. No claim about correctness on a GPU, or speed, is made. No CUDA host program exists in this book.
- **Platform:** x86-64 Linux with LLVM 18 and the `mlir-18` packages; POSIX only (Chapter 19's limits still hold).
- **Output format:** `mg.print` uses MLIR's runtime printer; its format (with the `base@` address) is not Mountain Goat's design.
- **The driver hides the C compiler's stderr** during the final link (shown above to have hidden a real error once). A better driver would show it.

## Reproducing

```sh
cd docs/part20/code
./build.sh                      # builds ./build/mg-opt (Chapter 20's)
./mgc run examples/03_dynamic.mg
./mgc ptx examples/05_gpu.mg
./demo.sh > demo_out.txt        # all ten examples
cpp/run.sh                      # the C++ program
cd ../part15/code && ./run_lit.sh   # 60 tests
```

## Chapter summary

- Mountain Goat finally has a **surface syntax** and a front end: `.mg` files are parsed, shape-checked with file-and-line errors, and translated to `mg` dialect MLIR.
- The driver `mgc` runs every stage built in the book (front end, dialect lowering with run-time shape checks, Chapter 19's stderr abort, LLVM IR, clang) behind one command, and keeps every intermediate file on request.
- A single new lowering, `tensor.cast` to `memref.cast`, was needed so fixed-shape values can be passed to dynamic-shape functions.
- Ten example programs ran for real: static, dynamic, mismatched, composed, and one compiled to PTX.
- `mgc lib` generates a C++ header, so ordinary C++ code calls compiled Mountain Goat functions; static shape errors throw, dynamic ones abort with a message on stderr.
- The CUDA story ends at PTX: real, inspected, and not launched.
- Eight new tests (60 total). Each test file was shown to fail under at least one injected bug; that is a weaker claim than "each test is strong", and Chapter 21's review section shows what the difference looks like.

## Self-check questions

1. What is the difference between a front end and a driver? Which parts of this chapter are each?

    ??? note "Answer"
        A **front end** reads the source text, checks it, and produces the compiler's internal form: here `mgfront.py`, which parses `.mg` text and writes `mg`-dialect MLIR. A **driver** runs the stages in order and connects them: here `mgc`, which calls the front end, then `mg-opt`, `mlir-translate` and `clang`. The front end knows the *language*; the driver knows the *pipeline*.

2. Why does the front end accept `add([[1,2,3],[4,5,6]], [[1,2],[3,4],[5,6]])` when `add` is declared `tensor[?x?]`, and what stops it at run time?

    ??? note "Answer"
        The front end can only compare dimensions it knows. Both parameters are `tensor[?x?]`, so it accepts any arguments that fit `?x?`; the sizes 2x3 and 3x2 are not compared against each other. At run time the lowering of `mg.add` compares the actual extents with `cf.assert`, and Chapter 19's pass makes that assert write its message to stderr and abort.

3. Why did the first GPU example produce no kernel, and what changed to fix it?

    ??? note "Answer"
        With `let` constants as inputs, `mg.add` of two `mg.constant` operands was folded by the compiler into a single precomputed constant, so the program became stores of the final numbers: no loop, hence no loop to turn into a kernel. The fix was to make the inputs function parameters, whose values the compiler cannot know, so the addition survives as a loop.

4. Why can the C++ wrapper throw an exception for `rot` but not for a failed dynamic check in `add`?

    ??? note "Answer"
        The `rot` parameter has a static shape (2x3), which the generated C++ code can compare against the matrix's `rows` and `cols` before calling anything, so it throws `std::invalid_argument`. A failed dynamic check happens *inside* the compiled code, which has no way to throw a C++ exception: it writes its message and calls `abort()`, which ends the process.

5. What does `tensor.cast` from `tensor<2x3xf64>` to `tensor<?x?xf64>` change, and what would a cast in the other direction need that this one does not?

    ??? note "Answer"
        It changes only the static type: the data is the same, the compiler just stops promising the sizes. Static to dynamic is always safe. The reverse direction (`?x?` to `2x3`) would claim sizes the compiler cannot know, so a correct lowering would need a run-time check that the actual sizes are 2 and 3.

6. Which of the five breakages in `prove_tests_can_fail_out.txt` is caught by the `cpp-interop` test, and why?

    ??? note "Answer"
        The `cpp-interop` test is caught by 'driver forgets Chapter 19's stderr pass': that test checks the abort message on stderr for the C++ program's mismatch run, and without the pass the message goes to stdout (and is lost when stdout is not a terminal).

7. Why is the CUDA host program not in this chapter, and what exactly would it need that this environment lacks?

    ??? note "Answer"
        There is no GPU and no CUDA driver in this environment, and no `cuda.h` to compile against. Such a program would load the PTX with `cuModuleLoadData` and launch with `cuLaunchKernel`, passing the 23 kernel parameters in Chapter 10's order; none of that can be built or run here, and the book does not print code it never executed.
