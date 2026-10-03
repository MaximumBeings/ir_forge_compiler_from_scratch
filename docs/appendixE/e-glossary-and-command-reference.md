# Appendix E. Glossary and Command Reference

![Mountain goats in space helmets on Io, a moon of Jupiter](../assets/goats/appx-e.svg){ style="display:block;margin:0 auto;max-width:100%;height:auto;border-radius:6px" }

The first half is a glossary of the terms the book uses, each with the chapter that explains it; the second half lists, in one place, the commands, options and passes you can run. The chapter index at the end is generated from the chapter pages. The pass list and the usage texts were produced by running the tools themselves (`appendixE/code/list_passes.sh`).

## E.1 Glossary

| term | meaning | where |
|---|---|---|
| **adjoint** | the derivative of the loss with respect to a value: how much the loss changes if that value changes | Ch 45 |
| **affine** (dialect) | MLIR's dialect of loops whose bounds and indexing are affine expressions, which makes them analysable | Ch 4, 7; App B |
| **attention** | a layer that mixes each position's value from the others, weighted by how well queries match keys (a softmax of scores) | Ch 29, 30, 33 |
| **backward pass** | computing the gradient of a loss by walking the program's operations in reverse | Ch 33 to 35, 45 |
| **basic block** | a straight-line run of instructions ending in a branch or return | App C |
| **broadcasting** | stretching a size-1 dimension to meet another operand (`RxC` with `1xC`) | Ch 22; App A |
| **bufferization** | replacing value-semantics `tensor`s with `memref` buffers in memory | Ch 6 |
| **canonicalization** | the standard clean-up pass: folds constants, removes dead operations | Ch 3; App B |
| **dialect** | a named group of MLIR operations, types and attributes (`arith`, `affine`, `mg`, ...) | Ch 2; App B |
| **dynamic shape** | a dimension whose size is unknown at compile time (written `?`) | Ch 13, 14 |
| **FileCheck / lit** | LLVM's test tools: `lit` runs test files, `FileCheck` matches their output against `CHECK:` lines | Ch 15 |
| **fast-math flags** | per-instruction permissions (`reassoc`, `contract`, `nnan`, ...) that let LLVM reorder or fuse floating-point arithmetic | Ch 44 |
| **fusion** | merging two loops into one so intermediate values stay in registers | Ch 7, 18 |
| **GA-1** | the book's model of a matrix accelerator, used to study tiling and loop order | Ch 40, 41 |
| **gradient** | the vector of derivatives of a loss with respect to its parameters | Ch 26, 33, 45 |
| **Hessian** | the matrix of second derivatives of a loss; the book computes its product with a vector | Ch 46 |
| **lowering** | rewriting operations of a higher-level dialect into lower-level ones | Ch 4, 5; App B |
| **memref** | an MLIR type for a reference to a buffer in memory, with sizes and strides | Ch 1; App B |
| **mutation test** | a test of the *tests*: break the code on purpose and check that the checker fails | Ch 15 and every chapter's "wrong versions" section |
| **NVVM / PTX** | NVIDIA's flavour of LLVM IR, and the assembly language of NVIDIA GPUs | Ch 10, 11 |
| **outlining** | moving a repeated piece of code into a shared function | Ch 38, 43 |
| **pass** | a program transformation on a module; a *pipeline* is a list of passes | Ch 3; App B |
| **phi** | the LLVM IR instruction that picks a value according to which block control came from | App C |
| **progressive lowering** | lowering in many small steps, one level of abstraction at a time | Ch 4, 5 |
| **region** | the list of blocks an MLIR operation can contain (a loop body, a function body) | App B |
| **reverse-mode differentiation** | computing all the derivatives of a scalar loss in one backward walk over the program | Ch 45 |
| **SSA** | static single assignment: every value is defined exactly once | App B, C |
| **softmax** | exponentiate and normalise a row so it sums to 1 | Ch 29 |
| **tile / tiling** | splitting a loop nest into blocks that fit a small fast memory | Ch 7, 40 |
| **vectorization** | doing one instruction on several elements at once (SIMD) | Ch 37, 44 |

## E.2 `mgc`, the driver

```text
--8<-- "docs/appendixE/code/mgc_usage_out.txt"
```

| subcommand | does |
|---|---|
| `mgc run prog.mg` | compile to a native executable and run it |
| `mgc build prog.mg [-o exe]` | compile to a native executable |
| `mgc lib prog.mg [-o dir]` | compile the `def`s to `prog.o` plus a C++ header `prog.h` (no `main`) |
| `mgc mlir prog.mg` | print the `mg`-dialect MLIR the front end produces |
| `mgc ptx prog.mg` | compile to PTX (nothing is launched) and print it |

| option | meaning | chapter |
|---|---|---|
| `-O0` to `-O3` | optimisation level of the final `clang` step (default `-O0`) | 23 |
| `--passes "..."` | extra `mg-opt` passes on the affine IR, before lowering (quote as one argument) | 23 |
| `--matmul-order ikj\|ijk` | loop order `mg.matmul` is lowered to (default `ijk`) | 24 |
| `--no-reverse-loops` | use MLIR's own `--convert-scf-to-cf` instead of lowering last to first (the default since Chapter 43) | 42, 43 |
| `--no-outline` | do not outline loop nests into shared functions (outlining is the default since Chapter 43) | 38, 43 |
| `--fast-math[=flags]` | set fast-math flags on floating-point operations (off by default; in the Chapter 44 version of `mgc`, `part44/code/mgc`) | 44 |

Environment variables: `MG_OPT` (which `mg-opt` to use), `MGC_KEEP=dir` (keep every intermediate file), `MGC_CFLAGS` (extra flags for `clang`, for example `-march=native`), `MGC_CLANG` (which clang to call).

## E.3 The passes this book adds to `mg-opt`

`mg-opt` is built from MLIR's own pass library plus the following five passes and the `mg` dialect (as printed by `mg-opt --help` for the Chapter 44 build; comparing its option list with `mlir-opt-18 --help` shows these and their parameters (`flags`, `matmul-order`, `min-loops`) as the only differences, and `mg-opt` registers only a subset of `mlir-opt`'s passes):

```text
--8<-- "docs/appendixE/code/passes_out.txt"
```

## E.4 The Python tools of Chapters 45 and 46

`autograd.py` (Chapter 45) writes a Mountain Goat program that computes a loss and its gradients, or takes gradient-descent steps; `hvp.py` (Chapter 46) wraps it to compute Hessian-vector products:

```text
--8<-- "docs/appendixE/code/autograd_usage_out.txt"
```

## E.5 Running the book's tests

```sh
cd docs/part44/code && ./build.sh          # build mg-opt (needs mlir-18-tools, libmlir-18-dev, cmake)
cd ../../part15/code && ./run_lit.sh       # the whole test suite (about 2 minutes)
```

## E.6 Chapter index

--8<-- "docs/appendixE/code/chapter_index.txt"
