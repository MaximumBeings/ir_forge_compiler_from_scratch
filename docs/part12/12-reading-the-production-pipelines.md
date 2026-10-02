# 12. Reading MLIR's Own Production Pipelines: What This Book's Compiler Is Missing

**What you will understand:** how this book's Mountain Goat pipeline compares to the real, in-tree pass pipelines that ship inside MLIR itself, read directly from the source and shown on this page, not recalled. It also settles three explanations Chapter 11 could only call hypotheses, by pairing each real symptom with the exact lines of MLIR's source that cause it, and it corrects one claim Chapter 10 got wrong. Every excerpt of LLVM code below is embedded from an unmodified copy kept in the repository (with its provenance and license in `code/llvm-18.1.3/NOTICE.md`).

**What you need to know first:** Chapters 10 and 11's GPU pipeline. New ground: reading MLIR's own pipeline-construction C++, and the idea that a "pipeline" is just an ordered list of passes.

!!! tip "Compile and run"
    Every command, listing and output on this page is reproduced by the commands in [Reproducing this chapter](#reproducing-this-chapter) at the bottom of the page, which also lists what must be built first. The chain of builds is in [Getting Started](../getting-started.md#which-build-does-each-chapter-need).


!!! note "A wrong or missing answer here is the point"
    This chapter's controls and reproductions are **supposed** to look broken: a wrong answer, a crash, or a non-zero exit status. They show what happens without the fix or without the real behavior. The correct build's output is shown beside them. Each script says so in its own header.

## Background: what a pass pipeline is

A compiler built on MLIR does its work as a sequence of **passes**, each rewriting the IR one step closer to machine code. A *pass pipeline* is nothing more than a list of those passes in a fixed order, optionally with options. Everything in Chapters 4 through 11 was an `mlir-opt-18` command line naming passes in order. MLIR also ships a few *packaged* pipelines, written in C++, that bundle a recommended order behind one name. Reading them answers a useful question: where does a pipeline that someone who knows MLIR well wrote differ from the one this book assembled by trial and error?

## Scope: which "production" compilers, and which not

Part 7 was queued as "how this book's design choices compare to real production MLIR-based compilers' own real, public lowering pipelines." This chapter does **less** than that, deliberately. The only source reachable and read here is the `llvm/llvm-project` repository itself, sparse-cloned at the exact tag matching this book's toolchain (`llvmorg-18.1.3`, commit `c13b748`). That gives two real pipelines that live inside MLIR:

- `GPUToNVVMPipeline.cpp` (130 lines), the source of `--gpu-lower-to-nvvm-pipeline` that Chapter 11 ran.
- `SparseTensorPipelines.cpp` (117 lines), the source of the sparse-tensor "sparsifier" pipeline.

**Out-of-tree compilers built on MLIR (IREE, for example, or Triton or XLA) were not read, and nothing here is claimed about them.** Nor does this chapter claim that these two pipelines are what any such compiler ships. The GPU pipeline file's own header says what it is:

```cpp
--8<-- "docs/part12/code/llvm-18.1.3/GPUToNVVMPipeline.cpp:9:11"
```

"A pass for **testing** the lowering to NVVM as a generally usable sink pass." That wording matters: it is MLIR's own reference pipeline, not a production compiler.

## Finding 1: the real GPU pipeline's pass order

The core of `GPUToNVVMPipeline.cpp`, as read from the repository:

```cpp
--8<-- "docs/part12/code/llvm-18.1.3/GPUToNVVMPipeline.cpp:44:130"
```

Three functions, called in this order: `buildCommonPassPipeline` (outline the kernel, lower control flow, function signatures and memrefs on the host, attach the NVVM target, lower affine, arithmetic and index, then canonicalize and CSE), `buildGpuPassPipeline` (nested inside each `gpu.module`: strip debug info, convert to NVVM, canonicalize, CSE, reconcile casts) and `buildHostPostPipeline` (**`gpu-to-llvm`, then `gpu-module-to-binary`**, then canonicalize, CSE, reconcile casts). Chapter 11's three dead ends, each with the real symptom and the lines that explain it:

### Dead end 1: the crash

Chapter 11 found `gpu-to-llvm` crashing `mlir-opt-18` when run *after* `gpu-module-to-binary`. `symptoms.sh` reproduces it and saves the top of the crash report:

```text
--8<-- "docs/part12/code/symptoms/1_crash_after_binary.txt"
```

The top frame is `GPUModuleOp::getTargetsAttr()`. The real pipeline above runs the two passes in the **opposite** order. And the source of the launch pattern (`GPUToLLVMConversion.cpp`, `ConvertLaunchFuncOpToGpuRuntimeCallPattern::matchAndRewrite`) reads:

```cpp
--8<-- "docs/part12/code/llvm-18.1.3/GPUToLLVMConversion.cpp:1114:1130"
```

The lookup is typed to `gpu::GPUModuleOp`. Once `gpu-module-to-binary` has replaced that op with a `gpu.binary`, the lookup finds nothing and returns null. The `assert` that is meant to catch this (line 1126) vanishes in a release build such as Ubuntu's, and `kernelModule.getTargetsAttr()` on the next lines then dereferences null. That matches the observed top frame exactly. **This is now an established cause, not a hypothesis**: reading the code is evidence, though it was not confirmed by rebuilding LLVM with assertions on, which would show the assert firing instead of a segfault.

### Dead end 2: `gpu.alloc` and `gpu.memcpy` silently not lowered

On the book's original, non-async host function, `gpu-to-llvm` ran without error and left the ops it was supposed to lower. `symptoms.sh` saves exactly which ones survive:

```text
--8<-- "docs/part12/code/symptoms/2_survivors_without_async.txt"
```

and, on the same input after `gpu-async-region`:

```text
--8<-- "docs/part12/code/symptoms/2_survivors_with_async.txt"
```

The source explains why. The helper that the alloc, dealloc and memcpy patterns call first:

```cpp
--8<-- "docs/part12/code/llvm-18.1.3/GPUToLLVMConversion.cpp:757:768"
```

A synchronous op fails the second test (`!op.getAsyncToken()`), and **`notifyMatchFailure` is not an error**: the pattern simply does not apply, and the op is left for a later legality check to complain about, which is the `failed to legalize operation 'builtin.unrealized_conversion_cast'` Chapter 11 saw. Note also that **the real pipeline does not contain `gpu-async-region`**. It expects its input to already be in async form; running that pass is the caller's job, which is what Chapter 11 ended up doing.

### Dead end 3: "got 23 kernel operands but expected 5"

Putting `gpu-to-llvm` *before* the kernel conversion got past the crash but failed verification (`3_operands_before_kernel_conversion.txt`):

```text
--8<-- "docs/part12/code/symptoms/3_operands_before_kernel_conversion.txt"
```

The branch quoted above, "If the module has Targets then just update the op operands", is what produced it:

```cpp
--8<-- "docs/part12/code/llvm-18.1.3/GPUToLLVMConversion.cpp:1128:1163"
```

`promoteOperands(...)` expands each memref launch argument into its descriptor scalars (the 23, again), and the pattern re-creates a `gpu.launch_func` with those. It takes this branch only when the module has targets (so `nvvm-attach-target` must already have run, which the legality rule at lines 607 to 622 also demands):

```cpp
--8<-- "docs/part12/code/llvm-18.1.3/GPUToLLVMConversion.cpp:607:622"
```

Run before the kernel itself is converted, the expanded launch and the unconverted kernel (still taking 5 memref arguments) disagree, which is the verifier error observed.

## Finding 2: Chapter 10 was wrong about the 23 parameters

Chapter 10 said narrowing the index to 32 bits "does nothing about the parameter count: that is a property of the `memref` type, not a pass option this chapter found to turn off." The packaged pipeline's option list (`mlir-opt-18 --help` on `--gpu-lower-to-nvvm-pipeline`) includes `kernel-bare-ptr-calling-convention`, and the source above threads it into both `convert-gpu-to-nvvm` (`useBarePtrCallConv`) and `gpu-to-llvm` (`kernelBarePtrCallConv`). A **bare pointer** convention passes each memref as one raw pointer instead of the seven-scalar descriptor. That loses the size and stride information, so it only works because every shape in this book is static. This chapter's first use of it, as a script:

```sh
--8<-- "docs/part12/code/pipeline.sh"
```

Real PTX header it produced (`bare.ptx`):

```text
--8<-- "docs/part12/code/bare.ptx:11:18"
```

and the launch call in the translated host code, whose last argument is now the parameter count:

```llvm
--8<-- "docs/part12/code/bare.ll:42:42"
```

| | default (Chapter 11) | `kernel-bare-ptr-calling-convention=1` | CUDA via `clang-18` (Chapter 10) |
|---|---|---|---|
| kernel `.param` declarations | 23 | **5** | 3 |
| `mgpuLaunchKernel` parameter count | 23 | **5** | n/a |
| PTX instructions | 25 | 25 | 19 |

The five parameters are the loop step and lower bound plus one raw pointer per matrix; the CUDA kernel's three are the pointers alone. The instruction count did not move (it is Chapter 10's 64-bit-index count), so the descriptor ABI cost 18 parameters but zero instructions, since the backend had already deleted the unused ones. The host glue still works with the narrower launch: Chapter 11's stub runtime was extended to accept either layout, and the bare-pointer build printed the same answer. The unedited run (`run_out.txt`: the stub's trace, then the program output):

```text
--8<-- "docs/part12/code/run_out.txt"
```

As in Chapter 11, this verifies the host-side parameter packing against a stub, not the PTX. Chapter 10 and Chapter 11's own text were updated in the same commit to point here.

## Finding 3: passes the real pipelines use that this book never did

The sparse-tensor pipeline, for comparison. It is longer (about seventy lines of pass additions) and shows what a pipeline for a more complex dialect looks like:

```cpp
--8<-- "docs/part12/code/llvm-18.1.3/SparseTensorPipelines.cpp:32:104"
```

Reading both files side by side with Chapters 1 through 11, the claim "this book never used these" is checked by `checks.sh` (section A counts how many files in the whole book mention each pass), and the output is real:

```sh
--8<-- "docs/part12/code/checks.sh"
```

```text
--8<-- "docs/part12/code/checks_out.txt"
```

| Real pipeline step | Where | This book |
|---|---|---|
| `expand-strided-metadata` | both pipelines | never used. Chapter 6 noted that One-Shot Bufferize's function boundary produces "a more general, strided memref layout"; this is the in-tree pass for lowering such layouts, and the book never exercised it |
| `canonicalize` + `cse` after every lowering stage | GPU pipeline, 3 times | `canonicalize` was used (Chapters 3, 4, 7); `cse` never |
| `convert-index-to-llvm`, `convert-math-to-llvm`, `convert-vector-to-scf` | GPU pipeline | never; no `index`, `math` or `vector` ops arise from `mg` |
| `strip-debug-info` on the kernel module | GPU pipeline | never used |
| `reconcile-unrealized-casts` once, at the very end | both | used, but per-chapter rather than once |
| one combined sparsification-and-bufferization pass | sparsifier | the book bufferizes separately (Chapter 6); that pass's internals were **not** read |
| `linalg` generalization/lowering at the start | sparsifier | the book has no `linalg` stage; `mg` lowers straight to `affine` loops |

Both pipelines are, structurally, **just ordered lists of passes**, parameterized by an options struct. Neither contains the interesting parts: those live in the passes. By that measure this book's own deliverable is the same kind of thing: Chapter 11's whole lowering is one `mlir-opt-18` command line.

## Finding 4: what is missing for production viability

Only things established by looking. Sections B to E of the check output above are the evidence:

- **Dynamic shapes are untested** (section C: zero `.mlir` files contain a `?` dimension; section B: the types are `2x2xf64` (109 and 99 occurrences), `3xf64`, `2x3xf64`, `1x1xf64` and `5xi32`). Whether the `mg` dialect and its lowerings handle dynamic shapes is **unknown**, not "no". *(Update, added after Chapter 13: now known. They did not, in three ways; Chapter 13 fixed the lowerings and found and fixed two more bugs.)* The bare-pointer GPU path above explicitly cannot.
- **There is no test suite** (section D: the only tracked files outside `docs/` are `.gitignore`, `TABLE_OF_CONTENTS.md` and `mkdocs.yml`: no `lit`/`FileCheck` tests, no CI). *(Update, added after Chapter 15: a 22-test `lit`/`FileCheck` suite now exists for Chapters 3 through 14's compiler behavior, with no CI; see Chapter 15.)* Every claim in this book at the time rested on a command having been run once and its output pasted. The in-tree pipelines are exercised by MLIR's own regression tests; this one by nobody but its author, which is why each chapter also records a reproduction script.
- **Four operations** (section E): `mg.constant`, `mg.add`, `mg.transpose`, `mg.print`, all on `f64`. No matmul, no control flow, no user-defined functions beyond what `func` already provides.
- **Nothing was ever executed on a GPU,** as Chapters 10 and 11 state. The real pipelines' end-to-end behavior on hardware is outside what this sandbox can test.
- **Single toolchain, single machine:** MLIR 18.1.3 on x86_64. Chapter 11's finding that `gpu.launch_func` is lowered at translation time describes this version; the repository is at a different state today and this chapter did not look.

## Reproducing this chapter

```bash
cd docs/part12/code
./pipeline.sh     # the bare-pointer variant, from Chapter 11's async.mlir
./symptoms.sh     # the three Chapter 11 symptoms, with real saved output
./checks.sh       # the grep/count evidence for Findings 3 and 4 -> checks_out.txt
```

The LLVM source was read from `llvm/llvm-project` at tag `llvmorg-18.1.3` with `git clone --depth 1 --filter=blob:none --sparse` and `git sparse-checkout set` on the directories named in `code/llvm-18.1.3/NOTICE.md`; the copies there are unmodified and every quoted line is embedded from them. As with Chapters 10 and 11, no documentation pages were read, only source code.

## Chapter summary

This chapter compared this book's pipeline with two real pipelines inside MLIR, `GPUToNVVMPipeline.cpp` and `SparseTensorPipelines.cpp`, read at tag `llvmorg-18.1.3`, with the exact excerpts embedded from unmodified copies. It turned Chapter 11's three hypotheses into established causes by pairing each reproduced symptom with the lines that cause it: the launch pattern looks the kernel module up by type and dereferences null once it has become a `gpu.binary`; the alloc, memcpy and dealloc patterns refuse non-async ops with a silent match failure; and the launch pattern expands memref operands into descriptor scalars, so running it before the kernel is converted gives "23 kernel operands but expected 5". It corrected a Chapter 10 claim (a `kernel-bare-ptr-calling-convention` option cuts the kernel from 23 parameters to 5), tabulated passes the real pipelines use that this book never did, and listed gaps from evidence.

Deliberately out of scope, stated explicitly: only these two in-tree pipelines were read, nothing is claimed about out-of-tree MLIR compilers, the crash cause was established by reading source and not by rebuilding LLVM with assertions, and the combined sparsification-and-bufferization pass was not read.

## Self-check questions

**1. Why does the real packaged pipeline run `gpu-to-llvm` before `gpu-module-to-binary`, and what happens in this toolchain if the order is reversed?**

Worked answer: `gpu-module-to-binary` replaces each `gpu.module` with a `gpu.binary`, and the launch lowering looks the kernel module up with a lookup typed to `gpu::GPUModuleOp`. After the replacement that lookup returns null; the `assert` guarding it is compiled out of a release build, and the next line calls `getTargetsAttr()` on the null result. The observed symptom is a segmentation fault whose top frame is exactly `GPUModuleOp::getTargetsAttr()`. Running `gpu-to-llvm` first, as the real pipeline does, avoids it.

**2. Which option reduces the kernel from 23 parameters to 5, and what does it cost?**

Worked answer: `kernel-bare-ptr-calling-convention=1` on the packaged pipeline, which passes each memref as one raw pointer instead of the seven-scalar descriptor. The five parameters are the loop step, the lower bound and three pointers. It costs the size and stride information, so it only works because every shape in the book is static (the option's help text says all memrefs must have static shape on the host side). The PTX instruction count did not change, since the backend had already deleted the unused descriptor reads: the ABI cost 18 parameters and zero instructions.

**3. The GPU pipeline's own header comment calls it a pass "for testing". Why does that wording limit what this chapter can claim?**

Worked answer: it says the file is MLIR's reference pipeline for testing the lowering to NVVM, not a production compiler's pipeline. The chapter can therefore say how this book's pass order compares to MLIR's own reference order, but not what any production compiler ships. Compilers built on MLIR outside the `llvm-project` repository were not read, and the chapter makes no claim about them.

**4. The chapter says the book "never used" `expand-strided-metadata`, `cse` and several other passes. How was that established, and why does the method matter?**

Worked answer: `checks.sh` counts, for each pass name, how many files in the whole book (Chapters 1 through 11, pages and code directories) mention it; the recorded result is zero for every one. The method matters because "never used" is a claim about 11 chapters of material, which is easy to assert from memory and wrong; counting turns it into an observation anyone can rerun, and the same script printed the type and shape evidence used for the gap list.

**5. Chapter 12 wrote that dynamic-shape support was "unknown, not no". Why that phrasing, and what did Chapter 13 find?**

Worked answer: at the time, every `.mlir` file in the book used static shapes (the check found no `?` dimension in any of them), so there was no evidence either way, and "no" would have been an unsupported claim. Chapter 13 tested it and found the answer was no in three ways (a verifier that wrongly rejected compatible shapes, and both lowerings failing on a dynamic `memref.alloc`), then fixed them and found two further bugs while doing so.
