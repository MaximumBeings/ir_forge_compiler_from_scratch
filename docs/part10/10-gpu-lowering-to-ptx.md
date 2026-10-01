# 10. GPU Lowering: Mountain Goat to the `gpu` Dialect, NVVM, and Real PTX

**What you will understand:** how a real Mountain Goat program (`mg.add`) is carried from Chapter 4's own `affine` loops, through MLIR's own real `gpu` dialect and its real `nvvm` dialect, down to real PTX text emitted by LLVM's own NVPTX backend -- and how that real, machine-generated PTX compares, instruction for instruction, against a real hand-written CUDA-style kernel compiled by `clang-18`. This chapter also says plainly what it could **not** do: launch the kernel. This book's own sandbox has no GPU.

**What you need to know first:** Chapter 4's own `--convert-mg-to-affine` output, Chapter 7's own `affine` loop passes, and Chapter 5's own memref-descriptor calling convention (each `memref` argument becomes several scalar parameters). New ground here: the `gpu` dialect's host/device split (`gpu.module`, `gpu.launch_func`) and PTX as an assembly language.

## What this sandbox can and cannot do (checked, not assumed)

Before writing a single pass, this chapter's own environment was probed directly:

```text
$ which nvcc nvidia-smi          # (no output: neither exists)
$ ls /dev | grep -i nvidia       # (no output)
$ nvptx-arch
Failed to 'dlopen' libcuda.so.1
$ llc-18 --version | grep -iE "nvptx|amdgcn"
    amdgcn      - AMD GCN GPUs
    nvptx       - NVIDIA PTX 32-bit
    nvptx64     - NVIDIA PTX 64-bit
```

So: **no GPU, no CUDA driver (`libcuda.so.1`), no `nvcc`, no CUDA SDK.** But the real `nvptx64` code generator *is* compiled into this LLVM, and `mlir-opt-18` really does carry the `gpu`, `nvvm` and `rocdl` dialects and the passes between them (`--convert-gpu-to-nvvm`, `--nvvm-attach-target`, `--gpu-module-to-binary`, all confirmed present in `mlir-opt-18 --help`). That decides this chapter's honest scope:

| Step | Done here? |
|---|---|
| Lower `mg` to a real `gpu.module` with a real kernel | **Yes**, real output below |
| Lower the kernel to the real `nvvm` dialect | **Yes** |
| Emit real PTX with LLVM's NVPTX backend | **Yes** |
| Compile an equivalent CUDA-style kernel with `clang-18` and compare | **Yes** (without the CUDA SDK; see below) |
| Assemble PTX to a cubin (`ptxas`), launch it, read results back | **No** -- no GPU, no `ptxas`, no driver |

Because nothing here was executed on a GPU, **this chapter does not claim the PTX computes the right answer on hardware.** What it establishes is that real MLIR and real LLVM accept every stage and produce the PTX shown. The numeric `[[6, 8], [10, 12]]` check Chapters 5 through 9 ended with has no equivalent in this chapter, and that absence is the chapter's most important caveat. The `-nocudainc -nocudalib` CUDA kernel below is likewise compiled, not run.

## Step 1: the same `mg.add` as before, lowered to `affine`

The input is Chapter 8's own unmodified `add_tensors.mlir`:

```mlir
func.func @add_tensors(%a: tensor<2x2xf64>, %b: tensor<2x2xf64>) -> tensor<2x2xf64> {
  %0 = mg.add %a, %b : tensor<2x2xf64>, tensor<2x2xf64> -> tensor<2x2xf64>
  func.return %0 : tensor<2x2xf64>
}
```

`mg-opt` was rebuilt from this book's own published sources (Chapter 3's dialect files, Chapter 5's `LowerToAffine.cpp`, Chapter 6's bufferization model, Chapter 7's `mg-opt.cpp` and `CMakeLists.txt`) and run:

```bash
./mg-opt add_tensors.mlir --convert-mg-to-affine -o add_affine.mlir
```

```mlir
func.func @add_tensors(%arg0: memref<2x2xf64>, %arg1: memref<2x2xf64>) -> memref<2x2xf64> {
  %alloc = memref.alloc() : memref<2x2xf64>
  affine.for %arg2 = 0 to 2 {
    affine.for %arg3 = 0 to 2 {
      %0 = affine.load %arg0[%arg2, %arg3] : memref<2x2xf64>
      %1 = affine.load %arg1[%arg2, %arg3] : memref<2x2xf64>
      %2 = arith.addf %0, %1 : f64
      affine.store %2, %alloc[%arg2, %arg3] : memref<2x2xf64>
    }
  }
  return %alloc : memref<2x2xf64>
}
```

## Step 2: a real false start, then the route that works

The obvious pass for this job is `--convert-affine-for-to-gpu`. The first attempt failed twice, in two different ways:

```text
$ mlir-opt-18 add_affine.mlir --convert-affine-for-to-gpu="gpu-block-dims=1 gpu-thread-dims=1"
<unknown>:0: error: unable to schedule pass 'ConvertAffineForToGPU' on a PassManager
intended to run on 'builtin.module'!
```

It is a `func.func` pass, so it has to be nested (`--pass-pipeline='builtin.module(func.func(...))'`). Nested, it fails differently:

```text
add_affine.mlir:6:14: error: 'affine.load' op index must be a valid dimension or symbol identifier
```

That pass leaves `affine.load` inside the new kernel body indexed by values (the GPU block/thread ids) that are not valid affine dimensions or symbols, so the result does not verify. This chapter did not dig into why further than that, and does not claim this is a bug in the pass as opposed to a use this chapter got wrong; it simply abandoned that route.

The route that worked goes through loop *parallelism* rather than loop *conversion*:

```bash
mlir-opt-18 add_affine.mlir --pass-pipeline='builtin.module(
  func.func(affine-parallelize, lower-affine, gpu-map-parallel-loops,
            convert-parallel-loops-to-gpu),
  gpu-kernel-outlining)' -o add_gpu.mlir
```

`affine-parallelize` proves the two `affine.for` loops have no loop-carried dependence and rewrites them as `affine.parallel`; `lower-affine` (Chapter 5's own pass) turns that into `scf.parallel`; `gpu-map-parallel-loops` assigns the outer loop to GPU *blocks* and the inner loop to GPU *threads*; `convert-parallel-loops-to-gpu` builds a `gpu.launch`; and `gpu-kernel-outlining` moves its body into a real `gpu.module`/`gpu.func`. Real output:

```mlir
module attributes {gpu.container_module} {
  func.func @add_tensors(%arg0: memref<2x2xf64>, %arg1: memref<2x2xf64>) -> memref<2x2xf64> {
    %alloc = memref.alloc() : memref<2x2xf64>
    ...
    gpu.launch_func  @add_tensors_kernel::@add_tensors_kernel
        blocks in (%0, %c1_0, %c1_0) threads in (%1, %c1_0, %c1_0)
        args(%c1 : index, %c0 : index, %arg0 : memref<2x2xf64>,
             %arg1 : memref<2x2xf64>, %alloc : memref<2x2xf64>)
    return %alloc : memref<2x2xf64>
  }
  gpu.module @add_tensors_kernel {
    gpu.func @add_tensors_kernel(%arg0: index, %arg1: index, %arg2: memref<2x2xf64>,
        %arg3: memref<2x2xf64>, %arg4: memref<2x2xf64>) kernel {
      %0 = gpu.block_id  x
      ...
      %3 = gpu.thread_id  x
      ...
      %14 = memref.load %arg2[%12, %13] : memref<2x2xf64>
      %15 = memref.load %arg3[%12, %13] : memref<2x2xf64>
      %16 = arith.addf %14, %15 : f64
      memref.store %16, %arg4[%12, %13] : memref<2x2xf64>
      gpu.return
    }
  }
}
```

(`...` marks lines elided for length; the full file is `code/add_gpu.mlir`.) The real shape of the launch: **2 blocks of 2 threads, one thread per matrix element**, block id as the row and thread id as the column. The kernel's first two arguments (`%c1`, `%c0`) are the original loop's step and lower bound, which the generated index math reuses as `block_id * step + lb`.

## Step 3: lowering the kernel to the `nvvm` dialect

```bash
mlir-opt-18 add_gpu.mlir --pass-pipeline='builtin.module(
  lower-affine,
  nvvm-attach-target{chip=sm_70 features=+ptx60},
  gpu.module(convert-gpu-to-nvvm{index-bitwidth=64}, reconcile-unrealized-casts))' \
  -o add_nvvm.mlir
```

`nvvm-attach-target` stamps the `gpu.module` with `#nvvm.target<chip = "sm_70">` (a Volta-generation target, chosen arbitrarily since nothing here runs); `convert-gpu-to-nvvm` rewrites `gpu.block_id x` into `nvvm.read.ptx.sreg.ctaid.x` and `gpu.thread_id x` into `nvvm.read.ptx.sreg.tid.x`, and converts the body into the `llvm` dialect. Real excerpt:

```mlir
gpu.module @add_tensors_kernel [#nvvm.target<chip = "sm_70">]  {
  llvm.func @add_tensors_kernel(%arg0: i64, %arg1: i64, %arg2: !llvm.ptr, %arg3: !llvm.ptr,
      %arg4: i64, %arg5: i64, %arg6: i64, %arg7: i64, %arg8: i64, %arg9: !llvm.ptr, ...
      %arg22: i64) attributes {gpu.kernel, nvvm.kernel} {
    ...
    %24 = nvvm.read.ptx.sreg.ctaid.x : i32
    %25 = llvm.sext %24 : i32 to i64
    %26 = nvvm.read.ptx.sreg.tid.x : i32
    %27 = llvm.sext %26 : i32 to i64
    ...
    %40 = llvm.fadd %34, %39  : f64
    llvm.store %40, %44 : f64, !llvm.ptr
    llvm.return
  }
}
```

Notice the kernel's signature: **23 parameters.** Each of the three `memref<2x2xf64>` arguments was expanded by Chapter 1's own descriptor rule into 7 scalars (allocated pointer, aligned pointer, offset, two sizes, two strides), plus the 2 index arguments: 2 + 3 x 7 = 23. The kernel then spends 21 `llvm.insertvalue` operations rebuilding descriptor structs it barely uses.

## Step 4: real PTX

```bash
mlir-opt-18 add_nvvm.mlir --gpu-module-to-binary="format=isa" -o add_bin.mlir
python3 decode_ptx.py add_bin.mlir > add_tensors_mlir.ptx
```

`--gpu-module-to-binary` with `format=isa` runs LLVM's NVPTX backend and stores the PTX as a string attribute on a `gpu.binary` op, escaped as hex (`\0A` for a newline), which is why `decode_ptx.py` exists; the first attempt at decoding it with a naive `unicode_escape` produced garbled text, caught only by looking at the output. After removing the 23 `.param` declarations for length, the real body is:

```text
ld.param.u64 	%rd1, [add_tensors_kernel_param_0];
ld.param.u64 	%rd2, [add_tensors_kernel_param_17];
cvta.to.global.u64 	%rd3, %rd2;
ld.param.u64 	%rd4, [add_tensors_kernel_param_1];
ld.param.u64 	%rd5, [add_tensors_kernel_param_10];
cvta.to.global.u64 	%rd6, %rd5;
ld.param.u64 	%rd7, [add_tensors_kernel_param_3];
cvta.to.global.u64 	%rd8, %rd7;
mov.u32 	%r1, %ctaid.x;
cvt.s64.s32 	%rd9, %r1;
mov.u32 	%r2, %tid.x;
cvt.s64.s32 	%rd10, %r2;
mul.lo.s64 	%rd11, %rd9, %rd1;
add.s64 	%rd12, %rd11, %rd4;
shl.b64 	%rd13, %rd12, 1;
add.s64 	%rd14, %rd13, %rd10;
shl.b64 	%rd15, %rd14, 3;
add.s64 	%rd16, %rd8, %rd15;
ld.global.f64 	%fd1, [%rd16];
add.s64 	%rd17, %rd6, %rd15;
ld.global.f64 	%fd2, [%rd17];
add.rn.f64 	%fd3, %fd1, %fd2;
add.s64 	%rd18, %rd3, %rd15;
st.global.f64 	[%rd18], %fd3;
ret;
```

You can read the program in it: two special-register reads (`%ctaid.x`, `%tid.x`), index arithmetic, two `ld.global.f64`, one `add.rn.f64`, one `st.global.f64`. The backend also deleted everything the kernel never used without being asked: the `block_id y`/`z`, `grid_dim` and `block_dim` reads and all the rebuilt descriptor structs are gone, and of the 23 declared parameters the body loads only 5 (`param_0`, `_1`, `_3`, `_10`, `_17`: the loop step, the lower bound, and the three aligned data pointers).

## Step 5: the same kernel as CUDA, compiled by `clang-18`

`nvcc` is unavailable, but `clang-18` can compile CUDA's device side itself. The CUDA headers that define `threadIdx`/`blockIdx` are also absent, so the kernel calls the NVVM builtins those names expand to (the first attempt spelled them `__builtin_nvvm_...` and clang's own error suggested the real name, `__nvvm_...`):

```cuda
extern "C" __attribute__((global)) void add_cuda(const double *a, const double *b, double *c) {
  int row = __nvvm_read_ptx_sreg_ctaid_x();
  int col = __nvvm_read_ptx_sreg_tid_x();
  int i = row * 2 + col;
  c[i] = a[i] + b[i];
}
```

```bash
clang-18 -x cuda --cuda-device-only --cuda-gpu-arch=sm_70 -nocudainc -nocudalib -S -O1 \
  cuda_add.cu -o cuda_add.ptx
```

Real PTX body:

```text
ld.param.u64 	%rd1, [add_cuda_param_0];
ld.param.u64 	%rd2, [add_cuda_param_2];
cvta.to.global.u64 	%rd3, %rd2;
ld.param.u64 	%rd4, [add_cuda_param_1];
cvta.to.global.u64 	%rd5, %rd4;
cvta.to.global.u64 	%rd6, %rd1;
mov.u32 	%r1, %ctaid.x;
mov.u32 	%r2, %tid.x;
shl.b32 	%r3, %r1, 1;
add.s32 	%r4, %r3, %r2;
mul.wide.s32 	%rd7, %r4, 8;
add.s64 	%rd8, %rd6, %rd7;
ld.global.f64 	%fd1, [%rd8];
add.s64 	%rd9, %rd5, %rd7;
ld.global.f64 	%fd2, [%rd9];
add.f64 	%fd3, %fd1, %fd2;
add.s64 	%rd10, %rd3, %rd7;
st.global.f64 	[%rd10], %fd3;
ret;
```

## The real comparison

Counts taken by `grep` over the three `.ptx` files in `code/`: `.param` lines are declarations (the 64-bit run's `add_tensors_mlir.ptx`, the `index-bitwidth=32` run's `add_tensors_mlir_idx32.ptx`, and `cuda_add.ptx`); instructions counts the `ld`/`st`/`mul`/`add`/`shl`/`cvt`/`mad`/`cvta`/`mov`/`ret` lines.

| | MLIR, `index-bitwidth=64` | MLIR, `index-bitwidth=32` | CUDA via `clang-18` |
|---|---|---|---|
| kernel `.param`s | 23 | 23 | 3 |
| instructions | 25 | 22 | 19 |
| index arithmetic | 64-bit (`mul.lo.s64`, `add.s64`, `shl.b64`) | 32-bit (`mad.lo.s32`, `shl.b32`, `add.s32`) | 32-bit (`shl.b32`, `add.s32`) |
| memory ops | 2 `ld.global.f64`, 1 `st.global.f64` | same | same |

The `index-bitwidth=32` column came from a second real run (`add_gpu.mlir` through `canonicalize`, then `convert-gpu-to-nvvm{index-bitwidth=32}`); it is also in `pipeline.sh`. What the table honestly shows:

- **The memory traffic is identical.** Both artifacts do exactly two 8-byte global loads, one `add` and one 8-byte global store. The mathematical work Mountain Goat's `mg.add` expresses survived the whole pipeline intact.
- **The gap is the calling convention and index width, not the arithmetic.** MLIR's kernel takes 23 parameters against CUDA's 3 because Chapter 1's memref-descriptor ABI carries sizes, strides and offsets the CUDA kernel simply hard-codes (`row * 2 + col`). Narrowing the index to 32 bits closes most of the instruction-count gap (25 to 22 against CUDA's 19) but does nothing about the parameter count: that is a property of the `memref` type, not a pass option this chapter found to turn off.
- **What this comparison cannot tell you:** which kernel is faster. Neither was run, and a 4-element add is dominated by launch overhead anyway. Instruction counts are a static proxy, not a measurement.
- **The CUDA kernel is not a fair "idiomatic CUDA" sample.** It was written to match the MLIR kernel's launch shape (2 blocks x 2 threads) and uses raw builtins because the CUDA headers are missing.

## What is still missing from a real GPU path

`gpu.launch_func` still sits in the host function, unlowered. *(Correction, added after Chapter 11: it is not `--gpu-to-llvm` alone that lowers the launch in this toolchain, and the load call is named `mgpuModuleLoadJIT`; see Chapter 11 for what actually happened.)* Turning it into real driver calls needs a GPU runtime (`mgpuModuleLoadJIT`, `mgpuLaunchKernel`, ...), and this machine has no such runtime library installed (`ls /usr/lib/llvm-18/lib | grep -iE "cuda|rocm"` found nothing GPU-related besides a Vulkan-transform static library). The host side also needs the memrefs to live somewhere the device can reach: right now `memref.alloc` is ordinary host memory, so on a real GPU this program would need `gpu.alloc`/`gpu.memcpy` or unified memory, which this chapter did not attempt. Those are the concrete steps between this chapter's PTX and a real launch, left open rather than papered over.

## Reproducing this chapter

Everything above is regenerated by `code/pipeline.sh` (verified here by running it in an empty directory and byte-comparing every output against the files in `code/`). It needs a built `mg-opt` (`MG=/path/to/mg-opt ./pipeline.sh`) plus `mlir-opt-18` and `clang-18`. Packages beyond Chapter 1's own: `mlir-18-tools libmlir-18-dev` as before, and in this chapter's sandbox `llvm-18-dev` also had to be installed (after an `apt-get update`) before CMake could find LLVM for rebuilding `mg-opt`.

## What this chapter does not cite

Chapters 1 through 9 cite the `llvm/llvm-project` repository's own `mlir/docs/` for claims about MLIR's design. This chapter does not: every statement above about what a pass does is taken from running it and reading its output (and `mlir-opt-18 --help` descriptions), not from the project's documentation, which was not read for this chapter. Treat the explanations of *why* `convert-affine-for-to-gpu` failed, and of the ABI cost of memref descriptors, as observations from this one small example.
