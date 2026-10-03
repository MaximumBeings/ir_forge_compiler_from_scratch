# Getting Started

This book builds a real MLIR dialect and lowers it, through real MLIR passes, down to real LLVM IR and genuine native machine code -- every pipeline stage in this book is run against a real, installed MLIR/LLVM toolchain, confirmed directly rather than assumed.

New to LLVM or MLIR? Read [Background: LLVM and MLIR in Twenty Minutes](background.md) first (or after this page): it explains, with real commands and output, what LLVM IR and MLIR are and how a program is lowered step by step to a running executable.

## Installing a toolchain

```bash
clang-18 --version          # the real LLVM/Clang frontend and backend, needed from Chapter 1 onward
mlir-opt-18 --version        # the real MLIR optimizer/pass driver
mlir-translate-18 --version   # translates between MLIR's own LLVM dialect and real LLVM IR text
llvm-config-18 --version       # reports this toolchain's own real installed version/paths
```

On Debian/Ubuntu (this book's own confirmed authoring platform, Ubuntu 24.04 "noble"), the base LLVM/Clang toolchain is `apt-get install clang llvm`; the real MLIR tools are a separate package, not pulled in automatically: `apt-get install mlir-18-tools libmlir-18-dev`. Ubuntu's own packaging keeps several real LLVM major versions installable side by side, which is why every tool in this book is invoked with its own explicit version suffix (`mlir-opt-18`, not a bare `mlir-opt`) -- confirmed directly in this book's own authoring environment, where `mlir-opt` alone resolves to nothing at all.

## The honesty discipline this book follows

This book's own confirmed authoring environment is a single cloud sandbox (x86_64 Ubuntu 24.04), with a real, version-checked `clang-18`/`mlir-opt-18`/`mlir-translate-18` toolchain and no cross-compilation involved: every binary this book produces targets the same architecture the toolchain itself runs on.

- **Every real MLIR snippet shown in this book is genuinely parsed and verified** by `mlir-opt-18` -- if it didn't parse, the page would not show it parsing.
- **Every real lowering pipeline shown in this book is genuinely run**, pass by pass, with the real intermediate IR this book claims it produces captured directly from `mlir-opt-18`'s own real output, not reconstructed by hand afterward.
- **Every real LLVM IR shown in this book is genuinely produced by `mlir-translate-18`**, not hand-written to match what the lowering "should" produce.
- **Every real executable this book builds is genuinely compiled and run**, with its own real, captured output -- including real compiler warnings, when the toolchain produces them -- locked into the page unedited.
- **From Chapter 10 on, and in every chapter's "complete source files" section, the code and outputs on the page are embedded from the repository when the site is built** (MkDocs snippets with `check_paths` enabled), so a page cannot drift from the file it shows, and a missing file fails `mkdocs build --strict`. Chapters 1 through 9 were written with pasted excerpts; their `code/` directories hold the full files, which each page now also embeds in a collapsed section.
- **Real facts this book states about MLIR's or LLVM's own design** are cited to the `llvm/llvm-project` repository's own real, official documentation (the `mlir/docs/` and `llvm/docs/` directories), read directly rather than paraphrased from memory, wherever a direct citation is practical. Where the project's own rendered documentation website is unreachable from this book's own authoring environment, the identical real text is still available directly from the project's own source repository, and that is what this book cites instead.

Every chapter states which of the above applies to its own code, so nothing is left for a reader to guess about how a claim in this book was actually established.

## Compile-line and pipeline conventions

- Parsing/verifying MLIR: `mlir-opt-18 file.mlir` (round-trips valid IR back out unchanged in substance; refuses to print anything at all if the IR does not verify)
- Lowering through real MLIR passes: `mlir-opt-18 file.mlir --pass-name-1 --pass-name-2 ... -o lowered.mlir`, with each chapter's own exact real pass names shown in full where they are introduced
- Translating MLIR's own `llvm` dialect to real LLVM IR text: `mlir-translate-18 --mlir-to-llvmir file.mlir -o file.ll`
- Compiling real LLVM IR to a real native object/executable: `clang-18 -c file.ll -o file.o`, then linked with any C harness the chapter needs
- Every chapter shows its own exact real invocation, including every flag, inline where the code it applies to is introduced

## Which build does each chapter need?

Each chapter's page starts with a "Compile and run" box (Chapters 1 to 9, 20 and 21) or points to its "Reproducing this chapter" section at the bottom (Chapters 10 to 19). The compiler tool, `mg-opt`, is rebuilt by each chapter that changes it, with a `build.sh` that assembles that chapter's source files (plus the earlier chapters' files it still uses) and builds into `./build/mg-opt`. Build the one you need; you do not need all of them.

| Chapters | Build before running | Notes |
|---|---|---|
| 1 | nothing | only `clang-18`, `mlir-opt-18`, `mlir-translate-18` |
| 2 to 7 | that chapter's own `part N/code/build.sh` | each is a self-contained build of the compiler as it was then |
| 8 | `part7/code/build.sh` | uses Chapter 7's `mg-opt` |
| 9 | nothing (the chapter's `run.sh` builds its own program) | needs `cmake` and the LLVM/MLIR development packages |
| 10, 11, 12 | a recent `mg-opt`, e.g. `part21/code/build.sh` | GPU chapters; compile-only, no GPU needed |
| 13 to 19 | the chapter's own `build.sh` (13, 14, 19), or `part14/code/build.sh` for 15 to 18 | the test-suite chapters can also use a newer build |
| 20 | `part20/code/build.sh` | adds the front end and the `mgc` driver |
| 21 | `part21/code/build.sh` | adds the arithmetic operations |
| 22 and the [language tour](tour/language-tour.md) | `part22/code/build.sh` | adds relu, reductions and broadcasting |
| 23 | `part22/code/build.sh` | Chapter 23 changes only the driver (`mgc -O`, `--passes`) |
| 24 | `part24/code/build.sh` | adds the `ikj` matmul loop order; the newest `mg-opt` runs everything |
| 27 | `part24/code/build.sh` | the contraction demo in `part27/code/cpp/` uses the newest compiler (`cpp/run.sh`) |
| 26 | `part24/code/build.sh` | the trainer in `part26/code/cpp/` uses the newest compiler (`cpp/run.sh`) |
| 25 | `./ci.sh` at the repository root | builds the newest compiler, runs the whole test suite and the docs build; also what the CI workflow runs |
| 28 | `part28/code/build.sh` | adds `mg.reshape` and `mg.permute`; `part28/code/mgc` runs the examples |
| 29 | `part29/code/build.sh` | adds `mg.exp`; the newest compiler |
| 30 | `part30/code/build.sh` | adds `mg.sqrt`; the compiler as of Chapter 30; `part30/code/mgc` runs the transformer |
| 31 | `part31/code/build.sh` | adds `mg.log`; the compiler as of Chapter 31; `part31/code/mgc` runs the trainer |
| 32 | `part32/code/build.sh` | adds `mg.ge`; the compiler from Chapter 32 to 37; `part32/code/mgc` runs the experiments |
| 33 | `part32/code/build.sh` | adds nothing to the compiler; `part33/code` has the programs, which run with Chapter 32's `mgc` |
| 34 | `part32/code/build.sh` | adds nothing to the compiler; `part34/code` has the programs, which run with Chapter 32's `mgc` |
| 35 | `part32/code/build.sh` | adds nothing to the compiler; `part35/code` has the programs, which run with Chapter 32's `mgc` |
| 36 | `part32/code/build.sh` | adds nothing to the compiler; `part36/code` has the programs, which run with Chapter 32's `mgc` |
| 37 | `part32/code/build.sh` | adds nothing to the compiler; `part37/code` has the scripts, which run with Chapter 32's `mgc` and LLVM's own `opt-18`, `clang-18` and `llvm-mca-18` |
| 38 | `part38/code/build.sh` | adds the `--mg-outline-loops` pass (`mgc --outline`); `part38/code/mgc` is the driver |
| 39 | `part38/code/build.sh` | adds nothing to the compiler; `part39/code` has the profiling scripts, which need `valgrind` |
| 40 | none | plain Python 3: the GA-1 simulator in `part40/code` needs no compiler |
| 41 | `part38/code/build.sh` | adds nothing to the compiler; `part41/code` is a Python back end that reads `mgc mlir` text and runs on Chapter 40's simulator |
| 42 | `part42/code/build.sh` | adds the `--mg-scf-to-cf-reverse` pass (`mgc --reverse-loops`) and registers the `scf` dialect in `mg-opt`; the newest compiler, which `run_lit.sh` and CI use; `part42/code/mgc` is the driver |
| 43 | `part42/code/build.sh` | no compiler change; `part43/code/mgc` is the newest driver (loops lowered last to first and big functions outlined by default; `--no-outline`, `--no-reverse-loops` turn them off) |
| the test suite (`part15/code/run_lit.sh`) | any build; it picks the newest that exists | the newest build runs every test |

Every build needs `cmake`, `make`, `llvm-18-dev`, `libmlir-18-dev` and `mlir-18-tools` (see above), and takes a few minutes the first time. Every `run.sh` and `demo.sh` writes its intermediate files under `./work/` or `./show/`, which are git-ignored.

## Prerequisites

This book assumes working knowledge of C (functions, pointers, `struct`s) and enough general compiler vocabulary to know what an intermediate representation, a basic block, and static single assignment (SSA) form are -- no prior MLIR or LLVM experience is assumed, and every dialect, operation, and pass this book uses is explained the first time it appears, cited to its own real, official source.
