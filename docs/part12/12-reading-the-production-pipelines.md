# 12. Reading MLIR's Own Production Pipelines: What This Book's Compiler Is Missing

**What you will understand:** how this book's Mountain Goat pipeline compares to the real, in-tree pass pipelines that ship inside MLIR itself -- read directly from the source, not recalled -- and what that comparison settles. It also settles three explanations Chapter 11 could only call hypotheses, and corrects one claim Chapter 10 got wrong.

**What you need to know first:** Chapters 10 and 11's GPU pipeline. New ground: reading MLIR's own pipeline-construction C++.

## Scope: which "production" compilers, and which not

Part 7 was queued as "how this book's design choices compare to real production MLIR-based compilers' own real, public lowering pipelines." This chapter does **less** than that, deliberately. The only source reachable and read here is the `llvm/llvm-project` repository itself, sparse-cloned at the exact tag matching this book's toolchain (`llvmorg-18.1.3`, commit `c13b748`). That gives two real pipelines that live inside MLIR:

- `mlir/lib/Dialect/GPU/Pipelines/GPUToNVVMPipeline.cpp` (130 lines), the source of `--gpu-lower-to-nvvm-pipeline` that Chapter 11 ran.
- `mlir/lib/Dialect/SparseTensor/Pipelines/SparseTensorPipelines.cpp` (117 lines), the source of the sparse-tensor "sparsifier" pipeline.

**Out-of-tree compilers built on MLIR (IREE, for example, or Triton or XLA) were not read, and nothing here is claimed about them.** Nor does this chapter claim that these two pipelines are what any such compiler ships; the GPU pipeline file's own header comment calls it "a pass for **testing** the lowering to NVVM as a generally usable sink pass." That wording matters: it is MLIR's own reference pipeline, not a production compiler.

## Finding 1: the real GPU pipeline's pass order, and what it settles

The core of `GPUToNVVMPipeline.cpp`, as read from the repository:

```cpp
void mlir::gpu::buildLowerToNVVMPassPipeline(OpPassManager &pm, const GPUToNVVMPipelineOptions &options) {
  buildCommonPassPipeline(pm, options);   // outlining, scf->cf, func->llvm, expand-strided-metadata,
                                          // nvvm-attach-target, lower-affine, arith->llvm, index->llvm,
                                          // canonicalize, cse
  buildGpuPassPipeline(pm, options);      // nested in gpu.module: strip-debug-info, convert-gpu-to-nvvm,
                                          // canonicalize, cse, reconcile-unrealized-casts
  buildHostPostPipeline(pm, options);     // gpu-to-llvm, THEN gpu-module-to-binary,
                                          // canonicalize, cse, reconcile-unrealized-casts
}
```

(Comments condensed from the file's own pass lists; the real file is 130 lines.) Compare with Chapter 11's three dead ends:

1. **The crash.** Chapter 11 found `gpu-to-llvm` crashing `mlir-opt-18` when run *after* `gpu-module-to-binary`, top frame `GPUModuleOp::getTargetsAttr()`, and left the cause as a hypothesis. The real pipeline runs them in the opposite order: `gpu-to-llvm` first, `gpu-module-to-binary` second. And the source of the launch pattern (`GPUToLLVMConversion.cpp`, `ConvertLaunchFuncOpToGpuRuntimeCallPattern::matchAndRewrite`) reads:

   ```cpp
   gpu::GPUModuleOp kernelModule;
   ...
   kernelModule = SymbolTable::lookupNearestSymbolFrom<gpu::GPUModuleOp>(launchOp, launchOp.getKernelModuleName());
   assert(kernelModule && "expected a kernel module");

   // If the module has Targets then just update the op operands.
   if (ArrayAttr targets = kernelModule.getTargetsAttr()) {
   ```

   The lookup is typed to `gpu::GPUModuleOp`. Once `gpu-module-to-binary` has replaced that op with a `gpu.binary`, the lookup finds nothing and returns null. The `assert` that is meant to catch this vanishes in a release build such as Ubuntu's, and `kernelModule.getTargetsAttr()` then dereferences null. That matches the observed top frame exactly. **This is now an established cause, not a hypothesis** (reading the code is evidence; it was not confirmed by rebuilding with assertions on, which would show the assert firing instead of a segfault).
2. **The silent non-lowering of `gpu.alloc`/`gpu.memcpy`.** The same file contains:

   ```cpp
   if (op.getAsyncDependencies().size() != 1)
     return rewriter.notifyMatchFailure(op, "Can only convert with exactly one async dependency.");
   if (!op.getAsyncToken())
     return rewriter.notifyMatchFailure(op, "Can convert only async version.");
   ```

   which is exactly why a non-async `gpu.alloc` was left alone until `gpu-async-region` ran, and why a match failure is silent: `notifyMatchFailure` is not an error. Note also that **the real pipeline does not contain `gpu-async-region`.** It expects its input to already be in async form (or to use only ops that lower synchronously); running that pass is the caller's job, which is what Chapter 11 ended up doing.
3. **"got 23 kernel operands but expected 5".** The branch quoted above, "If the module has Targets then just update the op operands," is the code that rewrote the launch with `promoteOperands(...)`, expanding each memref into its descriptor scalars, then re-created a `gpu.launch_func` with those. The launch pattern only takes that branch when the module has targets (`nvvm-attach-target` having run). Run before the kernel is converted, the expanded launch and the unconverted kernel disagree, which is the verifier error observed.

## Finding 2: Chapter 10 was wrong about the 23 parameters

Chapter 10 said narrowing the index to 32 bits "does nothing about the parameter count: that is a property of the `memref` type, not a pass option this chapter found to turn off." The real pipeline's option list (`mlir-opt-18 --help` on `--gpu-lower-to-nvvm-pipeline`) includes `kernel-bare-ptr-calling-convention`, and the source threads it into both `convert-gpu-to-nvvm` (`useBarePtrCallConv`) and `gpu-to-llvm` (`kernelBarePtrCallConv`). This chapter's first use of it:

```bash
mlir-opt-18 async.mlir \
  --gpu-lower-to-nvvm-pipeline="cubin-chip=sm_70 cubin-features=+ptx60 cubin-format=isa \
                                kernel-bare-ptr-calling-convention=1" -o bare_out.mlir
```

Real results (`code/pipeline.sh`; the PTX is `code/bare.ptx`):

| | default (Chapter 11) | `kernel-bare-ptr-calling-convention=1` | CUDA via `clang-18` (Chapter 10) |
|---|---|---|---|
| kernel `.param` declarations | 23 | **5** | 3 |
| `mgpuLaunchKernel` parameter count | 23 | **5** | n/a |
| PTX instructions | 25 | 25 | 19 |

The five parameters are the loop step and lower bound plus one raw pointer per matrix; the CUDA kernel's three are the pointers alone. The instruction count did not move (it is Chapter 10's 64-bit-index count), so the descriptor ABI cost 18 parameters but zero instructions, since the backend had already deleted the unused ones. The bare-pointer convention loses the size and stride information, so it only works because every shape here is static; the option's own help text in this build says so for the host side ("All memrefs must have static shape").

The host glue still works with the narrower launch. Chapter 11's stub runtime was extended to accept either layout (23 parameters: data pointers at indices 3, 10, 17; 5 parameters: at 2, 3, 4), and the bare-pointer build printed the same answer:

```text
[stub] launch add_tensors_kernel: grid=(2,1,1) block=(2,1,1) nparams=5
add_tensors([[1,2],[3,4]], [[5,6],[7,8]]) =
6 8
10 12
```

As in Chapter 11, this verifies the host-side parameter packing against a stub, not the PTX. Chapter 10 and Chapter 11's own text were updated in the same commit to point here.

## Finding 3: passes the real pipelines use that this book never did

Reading both files side by side with Chapters 1 through 11 (the lists below are from the two files; "never used" was checked against this book's own pipelines, not assumed):

| Real pipeline step | Where | This book |
|---|---|---|
| `expand-strided-metadata` | both pipelines | never used. Chapter 6 noted that One-Shot Bufferize's function boundary produces "a more general, strided memref layout"; this is the in-tree pass for lowering such layouts, and the book never exercised it |
| `canonicalize` + `cse` after every lowering stage | GPU pipeline, 3 times | `canonicalize` was used (Chapters 3, 4, 7); `cse` never |
| `convert-index-to-llvm`, `convert-math-to-llvm`, `convert-vector-to-scf` | GPU pipeline | never; no `index`, `math` or `vector` ops arise from `mg` |
| `strip-debug-info` on the kernel module | GPU pipeline | never used |
| `reconcile-unrealized-casts` once, at the very end | both | used, but per-chapter rather than once |
| one combined sparsification-and-bufferization pass | sparsifier | the book bufferizes separately (Chapter 6); that pass's internals were **not** read |
| `linalg` generalization/lowering at the start | sparsifier | the book has no `linalg` stage; `mg` lowers straight to `affine` loops |

Both pipelines are, structurally, **just ordered lists of passes** (about 120 lines each), parameterized by an options struct. Neither contains the interesting parts: those live in the passes. By that measure this book's own deliverable is the same kind of thing: Chapter 11's whole lowering is one `mlir-opt-18` command line.

## Finding 4: what is missing for production viability

Only things established by looking:

- **Dynamic shapes are untested.** Across every `.mlir` file in all chapters' `code/` directories, the tensor/memref types are `2x2xf64` (109 and 99 occurrences), `3xf64`, `2x3xf64`, `1x1xf64` and `5xi32`; no `?` dimension appears anywhere. Whether the `mg` dialect and its lowerings handle dynamic shapes is **unknown**, not "no". The bare-pointer GPU path above explicitly cannot.
- **There is no test suite.** The repository's tracked files outside `docs/` are `.gitignore`, `TABLE_OF_CONTENTS.md` and `mkdocs.yml`: no `lit`/`FileCheck` tests, no CI. Every claim in this book rests on a command having been run once and its output pasted. The in-tree pipelines are exercised by MLIR's own regression tests; this one by nobody but its author, which is why each chapter also records a reproduction script.
- **Four operations.** `mg.constant`, `mg.add`, `mg.transpose`, `mg.print` (checked in `MgOps.td`), all on `f64`. No matmul, no control flow, no user-defined functions beyond what `func` already provides.
- **Nothing was ever executed on a GPU,** as Chapters 10 and 11 state. The real pipelines' end-to-end behavior on hardware is outside what this sandbox can test.
- **Single toolchain, single machine:** MLIR 18.1.3 on x86_64. Chapter 11's finding that `gpu.launch_func` is lowered at translation time describes this version; the repository is at a different state today and this chapter did not look.

## Reproducing this chapter

`code/pipeline.sh` (verified in a clean run: `bare_out.mlir` byte-identical to the experiment's) rebuilds the bare-pointer variant from Chapter 11's `async.mlir`. The source excerpts above were read from `llvm/llvm-project` at tag `llvmorg-18.1.3` with `git clone --depth 1 --filter=blob:none --sparse` and `git sparse-checkout set` on the directories named; quoted lines are verbatim, comments in the pipeline excerpt are condensed and marked as such. As with Chapters 10 and 11, no documentation pages were read -- only source code.
