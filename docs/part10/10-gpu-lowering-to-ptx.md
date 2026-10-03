# 10. GPU Lowering: Mountain Goat to the `gpu` Dialect, NVVM, and Real PTX

![Mountain goats on the mountain in black and white at dusk](../assets/goats/ch-10.svg){ style="display:block;margin:0 auto;max-width:100%;height:auto;border-radius:6px" }

**What you will understand:** how a real Mountain Goat program (`mg.add`) is carried from Chapter 4's own `affine` loops, through MLIR's own `gpu` dialect and its `nvvm` dialect, down to real PTX text emitted by LLVM's own NVPTX backend, and how that machine-generated PTX compares, instruction for instruction, against a hand-written CUDA-style kernel compiled by `clang-18`. This chapter also says plainly what it could **not** do: launch the kernel. This book's sandbox has no GPU. Every file and output on this page is embedded from the repository, so nothing is elided and nothing is paraphrased.

**What you need to know first:** Chapter 4's `--convert-mg-to-affine` output, Chapter 7's `affine` loop passes, and Chapter 5's memref-descriptor calling convention (each `memref` argument becomes several scalar parameters). New ground here: the `gpu` dialect's host/device split (`gpu.module`, `gpu.launch_func`) and PTX as an assembly language. A short primer on both comes first.

!!! tip "Compile and run"
    Every command, listing and output on this page is reproduced by the commands in [Reproducing this chapter](#reproducing-this-chapter) at the bottom of the page, which also lists what must be built first. The chain of builds is in [Getting Started](../getting-started.md#which-build-does-each-chapter-need).


## Primer 1: how a GPU runs a function

A CPU function runs once per call. A **GPU kernel** is launched once but executes on *many threads at the same time*, and every thread runs the same code. Threads are organized in two levels:

- A **block** (also called a thread block or CTA) is a group of threads.
- A **grid** is the group of blocks one launch creates.

Each thread can ask "which block am I in, and which thread am I within it?" (`blockIdx`/`threadIdx` in CUDA; `gpu.block_id`/`gpu.thread_id` in MLIR; the PTX special registers `%ctaid` and `%tid`), and uses the answer to pick which piece of data to work on. For this book's 2x2 matrix addition the natural mapping is one thread per output element: **2 blocks of 2 threads**, the block index selecting the row and the thread index the column. That is what the compiler is about to be asked to build from Chapter 4's loop nest, whose outer loop becomes the blocks and whose inner loop becomes the threads.

## Primer 2: the stack of representations

Four layers appear in this chapter, from most to least portable:

| Layer | What it is | Where it appears |
|---|---|---|
| `gpu` dialect | MLIR's vendor-neutral model of "host code plus device kernels": `gpu.module` holds kernels, `gpu.launch_func` starts one | Step 2 |
| `nvvm` dialect | MLIR's model of NVIDIA-specific operations (special-register reads, the `nvvm.kernel` marker) | Step 3 |
| LLVM IR with the NVPTX target | ordinary LLVM IR that LLVM's `nvptx64` backend knows how to compile | inside Step 4 |
| **PTX** | NVIDIA's *virtual* assembly language, which a vendor tool (`ptxas`) later turns into the actual machine code for a specific chip | Step 4 |

PTX is assembly in the sense that each line is one instruction (`ld.global.f64` loads a 64-bit float from global memory, `add.rn.f64` adds two with round-to-nearest) and values live in numbered virtual registers (`%rd7`, `%fd3`, ...). It is *virtual* in that the register count is unlimited and the target chip decides the rest later. This chapter produces PTX but, as the next section shows, cannot assemble or run it.

## What this sandbox can and cannot do (checked, not assumed)

Before writing a single pass, the environment was probed. `probe.sh` records exactly what exists; its unedited output (`probe_out.txt`):

```sh
--8<-- "docs/part10/code/probe.sh"
```

```text
--8<-- "docs/part10/code/probe_out.txt"
```

So: **no GPU, no CUDA driver (`libcuda.so.1`), no `nvcc`, no CUDA SDK.** But the `nvptx64` code generator *is* compiled into this LLVM, and `mlir-opt-18` carries the `gpu`, `nvvm` and `rocdl` dialects and the passes between them. That decides this chapter's honest scope:

| Step | Done here? |
|---|---|
| Lower `mg` to a real `gpu.module` with a real kernel | **Yes**, real output below |
| Lower the kernel to the real `nvvm` dialect | **Yes** |
| Emit real PTX with LLVM's NVPTX backend | **Yes** |
| Compile an equivalent CUDA-style kernel with `clang-18` and compare | **Yes** (without the CUDA SDK; see below) |
| Assemble PTX to a cubin (`ptxas`), launch it, read results back | **No** (no GPU, no `ptxas`, no driver) |

Because nothing here was executed on a GPU, **this chapter does not claim the PTX computes the right answer on hardware.** What it establishes is that real MLIR and real LLVM accept every stage and produce the PTX shown. The numeric `[[6, 8], [10, 12]]` check Chapters 5 through 9 ended with has no equivalent in this chapter, and that absence is the chapter's most important caveat. The `-nocudainc -nocudalib` CUDA kernel below is likewise compiled, not run.

## Step 1: the same `mg.add` as before, lowered to `affine`

The input is Chapter 8's own unmodified `add_tensors.mlir`:

```mlir
--8<-- "docs/part10/code/add_tensors.mlir"
```

`mg-opt` was rebuilt from this book's published sources (Chapter 3's dialect files, Chapter 5's `LowerToAffine.cpp`, Chapter 6's bufferization model, Chapter 7's `mg-opt.cpp` and `CMakeLists.txt`) and run as `./mg-opt add_tensors.mlir --convert-mg-to-affine -o add_affine.mlir`. The result: the tensors became memrefs, and the add became a pair of nested loops.

```mlir
--8<-- "docs/part10/code/add_affine.mlir"
```

## Step 2: a real false start, then the route that works

The obvious pass for this job is `--convert-affine-for-to-gpu`, which converts top-level `affine.for` loops into GPU kernels. The first attempt failed twice, in two different ways. `false_starts.sh` records both verbatim (`false_starts_out.txt`):

```sh
--8<-- "docs/part10/code/false_starts.sh"
```

```text
--8<-- "docs/part10/code/false_starts_out.txt"
```

The pass works on a `func.func`, not a whole module, so it has to be nested (`--pass-pipeline='builtin.module(func.func(...))'`). Nested, it fails differently: it leaves `affine.load` inside the new kernel body indexed by values (the GPU block and thread ids) that are not valid affine dimensions or symbols, so the result does not verify. This chapter did not dig into why further than that, and does not claim this is a bug in the pass as opposed to a use this chapter got wrong; it simply abandoned that route.

The route that worked goes through loop *parallelism* rather than loop *conversion*:

```bash
mlir-opt-18 add_affine.mlir --pass-pipeline='builtin.module(
  func.func(affine-parallelize, lower-affine, gpu-map-parallel-loops,
            convert-parallel-loops-to-gpu),
  gpu-kernel-outlining)' -o add_gpu.mlir
```

- `affine-parallelize` proves the two `affine.for` loops have no loop-carried dependence and rewrites them as `affine.parallel`.
- `lower-affine` (Chapter 5's own pass) turns that into `scf.parallel`.
- `gpu-map-parallel-loops` assigns the outer loop to GPU *blocks* and the inner loop to GPU *threads*.
- `convert-parallel-loops-to-gpu` builds a `gpu.launch`.
- `gpu-kernel-outlining` moves its body into a real `gpu.module`/`gpu.func`.

The complete real output, nothing elided (`add_gpu.mlir`):

```mlir
--8<-- "docs/part10/code/add_gpu.mlir"
```

Reading it. **Host side** (lines 4 to 17): the `gpu.launch_func` names the kernel, a grid (`blocks in`) and a block (`threads in`), each three-dimensional with the unused y and z dimensions set to 1, and passes the arguments. The real shape of the launch is **2 blocks of 2 threads, one thread per matrix element**. **Device side** (lines 18 to 47): the `gpu.module` holds one `gpu.func ... kernel` whose first two arguments (`%arg0`, `%arg1`) are the original loop's step and lower bound, which the generated index arithmetic uses as `block_id * step + lb`. It reads `block_id`, `thread_id`, `grid_dim` and `block_dim` in all three dimensions (most are never used and disappear later), computes the row and column, and does the load/add/store.

## Step 3: lowering the kernel to the `nvvm` dialect

```bash
mlir-opt-18 add_gpu.mlir --pass-pipeline='builtin.module(
  lower-affine,
  nvvm-attach-target{chip=sm_70 features=+ptx60},
  gpu.module(convert-gpu-to-nvvm{index-bitwidth=64}, reconcile-unrealized-casts))' \
  -o add_nvvm.mlir
```

`nvvm-attach-target` stamps the `gpu.module` with `#nvvm.target<chip = "sm_70">` (a Volta-generation target, chosen arbitrarily since nothing here runs). `convert-gpu-to-nvvm` rewrites `gpu.block_id x` into `nvvm.read.ptx.sreg.ctaid.x` and `gpu.thread_id x` into `nvvm.read.ptx.sreg.tid.x`, and converts the body into the `llvm` dialect. The three parts of the result that matter, from the real `add_nvvm.mlir`: the module header and the kernel signature,

```mlir
--8<-- "docs/part10/code/add_nvvm.mlir:16:17"
```

the special-register reads,

```mlir
--8<-- "docs/part10/code/add_nvvm.mlir:42:46"
```

and the computation (note the three `getelementptr` and `load`/`store` pairs, the `fadd`, and where the pointers come from):

```mlir
--8<-- "docs/part10/code/add_nvvm.mlir:47:66"
```

The signature in the first excerpt is worth counting: **23 parameters.** A `memref<2x2xf64>` is not a bare pointer. By Chapter 1's descriptor rule it is an allocated pointer, an aligned pointer, an offset, two sizes and two strides, which is **seven** scalars; three memrefs plus the two index arguments give 2 + 3 x 7 = 23. The kernel then spends 21 `llvm.insertvalue` operations rebuilding descriptor structs it barely uses. The complete file, for anyone who wants every line:

??? note "Full `add_nvvm.mlir` (70 lines)"

    ```mlir
    --8<-- "docs/part10/code/add_nvvm.mlir"
    ```

## Step 4: real PTX

```bash
mlir-opt-18 add_nvvm.mlir --gpu-module-to-binary="format=isa" -o add_bin.mlir
python3 decode_ptx.py add_bin.mlir > add_tensors_mlir.ptx
```

`--gpu-module-to-binary` with `format=isa` runs LLVM's NVPTX backend and stores the PTX as a string attribute on a `gpu.binary` op, escaped as hex (`\0A` for a newline). That is why `decode_ptx.py` exists; the first attempt at decoding it with a naive `unicode_escape` produced garbled text, caught only by looking at the output:

```python
--8<-- "docs/part10/code/decode_ptx.py"
```

The real PTX, header and parameter list (the 23 declared parameters):

```text
--8<-- "docs/part10/code/add_tensors_mlir.ptx:1:36"
```

and the body, where the computation happens:

```text
--8<-- "docs/part10/code/add_tensors_mlir.ptx:37:67"
```

### Reading the body

The instruction meanings below are PTX's, stated from the instruction names and this program's behavior; this chapter did not consult NVIDIA's PTX manual.

- **Lines 41 to 48, loading parameters.** The body loads only what it needs: `param_0` (the loop step), `param_1` (the lower bound), and the three **aligned data pointers** (`param_3`, `param_10`, `param_17`: the second slot of each seven-field descriptor group). `cvta.to.global` converts each generic address to a global-memory address.
- **Lines 49 to 52, who am I.** `mov.u32 %r1, %ctaid.x` reads the block index and `mov.u32 %r2, %tid.x` the thread index; each is widened to 64 bits with `cvt.s64.s32`.
- **Lines 53 to 58, which element.** `mul.lo.s64`/`add.s64` compute `block * step + lb`, the row. `shl.b64 ..., 1` multiplies by 2 (the row stride of a 2-column matrix). Adding the thread index gives the element number; `shl.b64 ..., 3` multiplies by 8 (bytes per `f64`); adding the base pointer gives the address.
- **Lines 59 to 64, the computation.** Two `ld.global.f64` loads, one `add.rn.f64`, one `st.global.f64`. This is the whole mathematical content of the kernel.

The backend also deleted, without being asked, everything the kernel never used: the `block_id y`/`z`, `grid_dim` and `block_dim` reads and all the rebuilt descriptor structs are gone, and of the 23 declared parameters the body loads only **5** (`param_0`, `_1`, `_3`, `_10`, `_17`).

## Step 5: the same kernel as CUDA, compiled by `clang-18`

`nvcc` is unavailable, but `clang-18` can compile CUDA's device side itself. The CUDA headers that define `threadIdx`/`blockIdx` are also absent, so the kernel calls the NVVM builtins those names expand to (the first attempt spelled them `__builtin_nvvm_...` and clang's own error suggested the real name, `__nvvm_...`):

```cuda
--8<-- "docs/part10/code/cuda_add.cu"
```

```bash
clang-18 -x cuda --cuda-device-only --cuda-gpu-arch=sm_70 -nocudainc -nocudalib -S -O1 \
  cuda_add.cu -o cuda_add.ptx
```

The real PTX it produced:

```text
--8<-- "docs/part10/code/cuda_add.ptx:11:42"
```

The same shape as the MLIR kernel, with the loop bounds and row stride written into the source (`row * 2 + col`) instead of passed in: three parameters, 32-bit index arithmetic (`shl.b32`, `add.s32`), and the same two loads, add and store.

## The real comparison

The numbers below are computed by `compare.sh` from the three `.ptx` files, not counted by hand. `.param` lines are declarations; "instructions" counts the `ld`/`st`/`mul`/`add`/`shl`/`cvt`/`mad`/`cvta`/`mov`/`ret` lines:

```sh
--8<-- "docs/part10/code/compare.sh"
```

```text
--8<-- "docs/part10/code/compare_out.txt"
```

| | MLIR, `index-bitwidth=64` | MLIR, `index-bitwidth=32` | CUDA via `clang-18` |
|---|---|---|---|
| kernel `.param`s | 23 | 23 | 3 |
| instructions | 25 | 22 | 19 |
| index arithmetic | 64-bit (`mul.lo.s64`, `add.s64`, `shl.b64`) | 32-bit (`mad.lo.s32`, `shl.b32`, `add.s32`) | 32-bit (`shl.b32`, `add.s32`) |
| memory ops | 2 `ld.global.f64`, 1 `st.global.f64` | same | same |

The `index-bitwidth=32` column came from a second real run (`add_gpu.mlir` through `canonicalize`, then `convert-gpu-to-nvvm{index-bitwidth=32}`). The complete script that produces every artifact in this chapter:

```sh
--8<-- "docs/part10/code/pipeline.sh"
```

What the table honestly shows:

- **The memory traffic is identical.** Both artifacts do exactly two 8-byte global loads, one add and one 8-byte global store. The mathematical work Mountain Goat's `mg.add` expresses survived the whole pipeline intact.
- **The gap is the calling convention and index width, not the arithmetic.** MLIR's kernel takes 23 parameters against CUDA's 3 because Chapter 1's memref-descriptor ABI carries sizes, strides and offsets the CUDA kernel simply hard-codes. Narrowing the index to 32 bits closes most of the instruction-count gap (25 to 22 against CUDA's 19) but does nothing about the parameter count: that is a property of the `memref` type, not a pass option this chapter found to turn off. *(Correction, added after Chapter 12: this was wrong. `--gpu-lower-to-nvvm-pipeline` has a `kernel-bare-ptr-calling-convention` option that cuts the kernel to 5 parameters when all shapes are static; see Chapter 12.)*
- **What this comparison cannot tell you:** which kernel is faster. Neither was run, and a 4-element add is dominated by launch overhead anyway. Instruction counts are a static proxy, not a measurement.
- **The CUDA kernel is not a fair "idiomatic CUDA" sample.** It was written to match the MLIR kernel's launch shape (2 blocks x 2 threads) and uses raw builtins because the CUDA headers are missing.

## What is still missing from a real GPU path

`gpu.launch_func` still sits in the host function, unlowered. *(Correction, added after Chapter 11: it is not `--gpu-to-llvm` alone that lowers the launch in this toolchain, and the load call is named `mgpuModuleLoadJIT`; see Chapter 11 for what actually happened.)* Turning it into real driver calls needs a GPU runtime (`mgpuModuleLoadJIT`, `mgpuLaunchKernel`, ...), and this machine has no such runtime library installed (`ls /usr/lib/llvm-18/lib | grep -iE "cuda|rocm"` found nothing GPU-related besides a Vulkan-transform static library). The host side also needs the memrefs to live somewhere the device can reach: right now `memref.alloc` is ordinary host memory, so on a real GPU this program would need `gpu.alloc`/`gpu.memcpy` or unified memory, which this chapter did not attempt. Those are the concrete steps between this chapter's PTX and a real launch, left open rather than papered over.

## Reproducing this chapter

```bash
cd docs/part10/code
./probe.sh        > probe_out.txt          # what GPU tooling exists here
./false_starts.sh > false_starts_out.txt   # the abandoned --convert-affine-for-to-gpu attempt
MG=/path/to/mg-opt ./pipeline.sh           # every artifact in the chapter (needs a built mg-opt)
./compare.sh      > compare_out.txt        # the comparison table's numbers
```

`pipeline.sh` was verified by running it in an empty directory and byte-comparing every output against the files in `code/`. It needs a built `mg-opt` plus `mlir-opt-18` and `clang-18`. Packages beyond Chapter 1's own: `mlir-18-tools libmlir-18-dev` as before, and in this chapter's sandbox `llvm-18-dev` also had to be installed (after an `apt-get update`) before CMake could find LLVM for rebuilding `mg-opt`. One real trap recorded in `probe.sh`: `mlir-opt-18 --show-dialects` keeps waiting for input after printing, so scripts must give it `< /dev/null`.

## What this chapter does not cite

Chapters 1 through 9 cite the `llvm/llvm-project` repository's own `mlir/docs/` for claims about MLIR's design. This chapter does not: every statement above about what a pass does is taken from running it and reading its output (and `mlir-opt-18 --help` descriptions), not from the project's documentation, which was not read for this chapter. Treat the explanations of *why* `convert-affine-for-to-gpu` failed, and of the ABI cost of memref descriptors, as observations from this one small example.

## Chapter summary

This chapter carried a real Mountain Goat program, `mg.add`, from Chapter 4's `affine` loops down to real PTX: the loops were proven independent and mapped onto a 2-block-by-2-thread grid (`affine-parallelize`, `gpu-map-parallel-loops`, `convert-parallel-loops-to-gpu`, `gpu-kernel-outlining`), the kernel module was lowered to the `nvvm` dialect (`nvvm-attach-target`, `convert-gpu-to-nvvm`), and LLVM's NVPTX backend produced PTX (`gpu-module-to-binary{format=isa}`). An equivalent CUDA-style kernel was compiled with `clang-18` and compared: identical memory traffic (two global loads, one add, one store), but 23 kernel parameters against 3, because each `memref` crosses the call boundary as a seven-scalar descriptor. A first attempt with `--convert-affine-for-to-gpu` failed and is recorded.

Deliberately out of scope, stated explicitly: nothing was assembled or launched (no GPU, driver or `ptxas` exists in this sandbox), so the chapter makes no claim that the PTX computes the right answer on hardware, and the host side (device allocation, copies, the launch call) is left for Chapter 11. One claim in this chapter, that the 23-parameter count cannot be changed by a pass option, was wrong and is corrected in Chapter 12.

## Self-check questions

**1. The MLIR kernel declares 23 parameters and the CUDA kernel 3, yet both do the same two loads, one add and one store. Where do the 20 extra parameters come from?**

Worked answer: a `memref<2x2xf64>` does not cross a call boundary as a pointer. By Chapter 1's descriptor rule it becomes seven scalars: an allocated pointer, an aligned pointer, an offset, two sizes and two strides. The kernel takes three memrefs, so 3 x 7 = 21, plus two `index` arguments (the loop's step and lower bound), for 23. The CUDA kernel takes three raw pointers and writes the loop bounds and row stride into its source (`row * 2 + col`), so it has nothing else to pass.

**2. Of the 23 declared parameters, the PTX body loads only five. Which five, and why those?**

Worked answer: `param_0` and `param_1` (the loop step and lower bound, used in `block * step + lb`), and `param_3`, `param_10`, `param_17`, the *aligned pointer* slot, the second field, of each of the three descriptor groups (fields 2 to 8, 9 to 15 and 16 to 22 after the two index arguments). Sizes, strides and offsets are never read, because the shape is static and baked into the index arithmetic (`shl 1` for the row stride, `shl 3` for eight bytes per element). The backend deleted every unused read without being asked.

**3. `--convert-affine-for-to-gpu` failed twice. How did the two failures differ, and what did the working route do differently?**

Worked answer: the first failure was a scheduling error: the pass operates on a `func.func`, not on a `builtin.module`, so it must be nested in the pass pipeline. Nested, it produced `affine.load` operations indexed by GPU block and thread ids, which are not valid affine dimensions or symbols, so the result failed verification. The working route went through parallelism instead: `affine-parallelize` proved the loops independent, `lower-affine` turned them into `scf.parallel`, and the GPU mapping passes built the launch, with the kernel body using plain `memref.load`/`memref.store`. The chapter did not establish *why* the first route fails beyond that observation, and says so.

**4. Why does this chapter have no equivalent of the `[[6, 8], [10, 12]]` check that Chapters 5 through 9 ended with, and why is that its most important caveat?**

Worked answer: that check ran a program and compared its output with the independently known answer. Here nothing could be run: there is no GPU, no CUDA driver and no `ptxas`. The chapter therefore establishes only that real MLIR and real LLVM accept every stage and emit the PTX shown, which is a statement about the compiler, not about the kernel's correctness. Reading the PTX, the load, add and store look right, but reading is not executing, and the book's own discipline is that a plausible-looking result is not evidence.

**5. Switching `index-bitwidth` from 64 to 32 changed the instruction count from 25 to 22. What changed in the PTX, and what did not?**

Worked answer: the index arithmetic became 32-bit (`mad.lo.s32`, `shl.b32`, `add.s32` in place of `mul.lo.s64`, `add.s64`, `shl.b64`), and the two index parameters are now declared `.u32`. What did not change is the parameter count (still 23, because that comes from the memref descriptor ABI, not from the index width) and the memory traffic (still two loads and one store). Chapter 12 later showed that a different option, `kernel-bare-ptr-calling-convention`, is what changes the count.
