# Getting Started

This book builds a real MLIR dialect and lowers it, through real MLIR passes, down to real LLVM IR and genuine native machine code -- every pipeline stage in this book is run against a real, installed MLIR/LLVM toolchain, confirmed directly rather than assumed.

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

## Prerequisites

This book assumes working knowledge of C (functions, pointers, `struct`s) and enough general compiler vocabulary to know what an intermediate representation, a basic block, and static single assignment (SSA) form are -- no prior MLIR or LLVM experience is assumed, and every dialect, operation, and pass this book uses is explained the first time it appears, cited to its own real, official source.
