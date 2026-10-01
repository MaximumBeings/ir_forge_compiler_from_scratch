# 11. The GPU Host Side: Device Memory, Real Runtime Calls, and a Stub "Device"

**What you will understand:** what has to surround a GPU kernel on the host before it can run -- allocating device memory, copying inputs in and the result out, loading the kernel module, launching it with a grid, and cleaning up -- and how MLIR 18's real passes turn those steps into calls to a GPU runtime (`mgpuMemAlloc`, `mgpuModuleLoadJIT`, `mgpuLaunchKernel`, ...). This chapter closes the "what is still missing" list Chapter 10 ended with, as far as this sandbox allows, and it is explicit about the one thing it still cannot do: run the PTX.

**What you need to know first:** Chapter 10's kernel (`gpu.module @add_tensors_kernel`, 2 blocks x 2 threads, 23 parameters) and Chapter 8's harness (the same `Memref2D` struct-return convention). New ground: the async form of `gpu` ops, and where in the pipeline `gpu.launch_func` actually becomes runtime calls.

## What changed from Chapter 10's plan

Chapter 10 ended by saying the remaining steps were `--gpu-to-llvm`, a runtime library, and device-visible allocation. Two of those turned out differently when run:

- `--gpu-to-llvm` alone **does not** produce the launch call in this toolchain (LLVM/MLIR 18.1.3, Ubuntu's `mlir-opt-18`); the launch is lowered later, at LLVM IR translation time (below). Chapter 10's sentence naming `mgpuModuleLoad` was also slightly off: the real name is `mgpuModuleLoadJIT`.
- There is still no GPU runtime library on this machine, so a *stub* one is written instead.

## The host function, written by hand (and why)

Chapter 10's host code used plain `memref.alloc`, i.e. ordinary CPU memory, which a real device cannot read. This chapter's host function allocates device buffers with `gpu.alloc`, copies with `gpu.memcpy`, launches, copies the result back, and frees. **This function is hand-written, not generated from `mg.add`**: this book has no pass that inserts `gpu.alloc`/`gpu.memcpy` around a kernel, and writing one is not attempted here. The kernel module below it is Chapter 10's own `add_gpu.mlir` module, unchanged.

```mlir
func.func @add_tensors(%a: memref<2x2xf64>, %b: memref<2x2xf64>) -> memref<2x2xf64> {
  %da = gpu.alloc () : memref<2x2xf64>
  %db = gpu.alloc () : memref<2x2xf64>
  %dc = gpu.alloc () : memref<2x2xf64>
  gpu.memcpy %da, %a : memref<2x2xf64>, memref<2x2xf64>
  gpu.memcpy %db, %b : memref<2x2xf64>, memref<2x2xf64>
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c2 = arith.constant 2 : index
  gpu.launch_func @add_tensors_kernel::@add_tensors_kernel
      blocks in (%c2, %c1, %c1) threads in (%c2, %c1, %c1)
      args(%c1 : index, %c0 : index, %da : memref<2x2xf64>, %db : memref<2x2xf64>, %dc : memref<2x2xf64>)
  %r = memref.alloc() : memref<2x2xf64>
  gpu.memcpy %r, %dc : memref<2x2xf64>, memref<2x2xf64>
  gpu.dealloc %da : memref<2x2xf64>
  gpu.dealloc %db : memref<2x2xf64>
  gpu.dealloc %dc : memref<2x2xf64>
  return %r : memref<2x2xf64>
}
```

`mlir-opt-18` parses and verifies it as is. (`code/add_host_device.mlir` has the whole module.)

## A real run of dead ends

Getting from this file to runtime calls took several real failures. They are recorded because each one cost time and none is obvious from the pass names:

1. **`gpu-to-llvm` after `gpu-module-to-binary` crashes `mlir-opt-18`.** A pipeline of `nvvm-attach-target`, `convert-gpu-to-nvvm`, `gpu-module-to-binary{format=isa}`, `gpu-to-llvm`, then the usual `llvm` conversions died with a segmentation fault, top frame `mlir::gpu::GPUModuleOp::getTargetsAttr()`. This chapter did not diagnose it beyond narrowing it down: with the `gpu.launch_func` line deleted the same `gpu-to-llvm` run does not crash, so the launch is involved. Treat "it crashes because the kernel `gpu.module` has become a `gpu.binary`" as a hypothesis consistent with the top frame, not a confirmed cause.
2. **`gpu-to-llvm` silently left `gpu.alloc` and `gpu.memcpy` alone.** With the launch removed, the pass "succeeded" but a `grep` for `mgpu` calls found none: the ops were still there, and a later pass failed with `failed to legalize operation 'builtin.unrealized_conversion_cast'`. The fix was `gpu-async-region`, which rewrites these ops into their async form (with `!gpu.async.token`s and stream handling). The evidence that async form is the requirement is that adding that one pass changed the output from no runtime calls to `mgpuMemAlloc`/`mgpuMemcpy`/`mgpuStreamCreate`; this chapter did not read the pass's source.
3. **Putting `gpu-to-llvm` *before* the kernel conversion** got past the crash but failed verification: `'gpu.launch_func' op got 23 kernel operands but expected 5`. The pass had already expanded the three memref launch arguments into 23 scalars at the call site while the kernel still took 5 memref arguments. It is the same 2 + 3 x 7 = 23 expansion Chapter 10 found on the kernel side, now seen from the host side.

What finally worked was MLIR's own packaged pipeline, run after `gpu-async-region`:

```bash
mlir-opt-18 add_host_device.mlir \
  --pass-pipeline='builtin.module(func.func(gpu-async-region))' -o async.mlir
mlir-opt-18 async.mlir \
  --gpu-lower-to-nvvm-pipeline="cubin-chip=sm_70 cubin-features=+ptx60 cubin-format=isa" \
  -o pipe_out.mlir
```

(`--gpu-lower-to-nvvm-pipeline` appeared in `mlir-opt-18 --help` while writing Chapter 10; this is its first use. Its options in this version are named `cubin-*`; Chapter 10's standalone passes used `gpu-*`/pass-parameter names.)

## The launch is lowered at translation time

After that pipeline, `pipe_out.mlir` contains all the host-side runtime calls **except** the launch: `mgpuMemAlloc` x3, `mgpuMemcpy` x3, `mgpuMemFree` x3, `mgpuStreamCreate`/`Synchronize`/`Destroy` x2 each, one `malloc`. The kernel is a `gpu.binary` holding Chapter 10's PTX as a string, and `gpu.launch_func` is still an MLIR op, now with a stream operand and the 23 expanded operands. The remaining step is the one Chapter 1 already used for a different purpose:

```bash
mlir-translate-18 --mlir-to-llvmir pipe_out.mlir -o host.ll
```

Real excerpt of what `mlir-translate-18` emitted for that one op:

```llvm
%67 = call ptr @mgpuModuleLoadJIT(ptr @add_tensors_kernel_bin_cst, i32 2)
%68 = call ptr @mgpuModuleGetFunction(ptr %67, ptr @add_tensors_kernel_add_tensors_kernel_kernel_name)
call void @mgpuLaunchKernel(ptr %68, i64 2, i64 1, i64 1, i64 2, i64 1, i64 1, i32 0, ptr %15, ptr %20, ptr null, i64 23)
call void @mgpuModuleUnload(ptr %67)
```

Reading it: load the embedded PTX as a module (optimization level 2), look up the kernel by name, launch with grid `(2,1,1)` and block `(2,1,1)`, shared memory `0`, on stream `%15`, with `%20` as an array of **23 pointers, one per kernel parameter**, then unload. The geometry matches Chapter 10's kernel exactly. The conclusion that the launch is lowered here rather than by `gpu-to-llvm` comes from this observation (launch op present in `pipe_out.mlir`, runtime calls present in `host.ll`), not from documentation.

## A stub device, and what it can and cannot prove

`host.ll` is real LLVM IR that calls functions this machine does not have. A real build would link NVIDIA's runtime wrapper library. With none available, `code/stub_gpu_runtime.c` implements the same entry points on the CPU: "device memory" is `malloc`, copies are `memcpy`, and `mgpuLaunchKernel` runs a small C loop that reads the 23-pointer parameter array and does what the PTX does -- it reads parameters 0 and 1 (loop step and lower bound) and 3, 10 and 17 (the three data pointers), the exact five parameters Chapter 10 found the PTX body actually loads, and computes `c[(block * step + lb) * 2 + thread] = a[i] + b[i]`. It also checks that the module handed to `mgpuModuleLoadJIT` really contains `.entry add_tensors_kernel`.

Linking `host.ll` with Chapter 8's **unmodified** `harness.c` and the stub:

```bash
clang-18 -c host.ll -o host.o
clang-18 harness.c host.o stub_gpu_runtime.c -o add_tensors_stub_demo
./add_tensors_stub_demo
```

Real output (stub's trace on stderr first):

```text
[stub] stream create
[stub] alloc 32 bytes
[stub] alloc 32 bytes
[stub] alloc 32 bytes
[stub] memcpy 32 bytes
[stub] memcpy 32 bytes
[stub] module load: optLevel=2, PTX has .entry add_tensors_kernel: yes
[stub] launch add_tensors_kernel: grid=(2,1,1) block=(2,1,1) nparams=23
[stub] stream create
[stub] memcpy 32 bytes
add_tensors([[1,2],[3,4]], [[5,6],[7,8]]) =
6 8
10 12
```

`[[6, 8], [10, 12]]` is the same answer Chapters 5 through 9 produced by other routes. The trace shows the sequence the host code is supposed to perform: three 32-byte device buffers (2 x 2 x 8 bytes), two copies in, a launch, one copy out.

**A negative control**, because a check that cannot fail proves nothing: the same program was rebuilt with the stub kernel's arithmetic line removed. It printed `0 0 / 0 0` (the contents of a fresh `malloc`; those bytes are not guaranteed to be zero, they happened to be). So the answer above does depend on the launch parameters being packed and read correctly.

**What this establishes:** the host-side glue is correct end to end -- device allocation, host-to-device and device-to-host copies, launch geometry, the 23-parameter packing, and the descriptor handling for the returned memref, all through Chapter 8's own calling convention.

**What it does not establish:** that the PTX is correct, or that it assembles, or that it would run on any real GPU. The stub's kernel is **hand-written C that mirrors the PTX**, not an execution of it. Anything wrong in the PTX itself -- or any difference between how a real driver packs `mgpuLaunchKernel`'s parameter array and how this stub reads it -- is invisible to this check. A real run needs a GPU, the driver, the real runtime wrapper library, and `ptxas`; none exist in this sandbox.

## Reproducing this chapter

`code/pipeline.sh` runs every step above and was verified by running it in an empty directory and byte-comparing `pipe_out.mlir` and `host.ll` with the files in `code/`. Tools: `mlir-opt-18`, `mlir-translate-18`, `clang-18`; no packages beyond Chapter 10's. `run_out.txt` is the unedited output.

## What this chapter does not cite

As in Chapter 10, no `llvm-project` documentation was read. Every claim about where a lowering step happens comes from running the pass and reading its output. In particular, the explanations for the three dead ends are the most likely readings of what was observed, not verified root causes.
