# 11. The GPU Host Side: Device Memory, Real Runtime Calls, and a Stub "Device"

![Mountain goats on the mountain at night](../assets/goats/ch-11.svg){ style="display:block;margin:0 auto;max-width:100%;height:auto;border-radius:6px" }

**What you will understand:** what has to surround a GPU kernel on the host before it can run (allocating device memory, copying inputs in and the result out, loading the kernel module, launching it with a grid, and cleaning up) and how MLIR 18's real passes turn those steps into calls to a GPU runtime (`mgpuMemAlloc`, `mgpuModuleLoadJIT`, `mgpuLaunchKernel`, ...). This chapter closes the "what is still missing" list Chapter 10 ended with, as far as this sandbox allows, and it is explicit about the one thing it still cannot do: run the PTX. Every file, script and output below is embedded from the repository.

**What you need to know first:** Chapter 10's kernel (`gpu.module @add_tensors_kernel`, 2 blocks x 2 threads, 23 parameters) and Chapter 8's harness (the same `Memref2D` struct-return convention). New ground: the async form of `gpu` ops, and where in the pipeline `gpu.launch_func` actually becomes runtime calls.

!!! tip "Compile and run"
    Every command, listing and output on this page is reproduced by the commands in [Reproducing this chapter](#reproducing-this-chapter) at the bottom of the page, which also lists what must be built first. The chain of builds is in [Getting Started](../getting-started.md#which-build-does-each-chapter-need).


!!! note "A wrong or missing answer here is the point"
    This chapter's controls and reproductions are **supposed** to look broken: a wrong answer, a crash, or a non-zero exit status. They show what happens without the fix or without the real behavior. The correct build's output is shown beside them. Each script says so in its own header.

## Primer: what the host does around a kernel

A GPU has its own memory. A kernel can only read and write memory on the device, so a host program that wants to use one must, in order:

1. **Allocate** buffers on the device for the inputs and the output.
2. **Copy** the inputs from host memory to those device buffers.
3. **Load** the compiled kernel (here, the PTX text) as a *module*, and look up the kernel by name.
4. **Launch** it with a grid size, a block size, and an array of pointers to its arguments.
5. **Copy** the result back, and **free** the device buffers.

Operations on a GPU are normally queued on a **stream** and run asynchronously relative to the host: the host enqueues work and waits only when it needs the result. MLIR models this with *async tokens*: each async `gpu` operation takes the tokens of the operations it depends on and returns a token of its own, and a `gpu.wait` blocks the host on a token. Everything above is real runtime-library work (NVIDIA's driver wrappers, or MLIR's own wrapper library), which is why the compiled host code ends up as *calls* to functions with names like `mgpuMemAlloc`: the compiler emits the calls, and a library implements them.

## What changed from Chapter 10's plan

Chapter 10 ended by saying the remaining steps were `--gpu-to-llvm`, a runtime library, and device-visible allocation. Two of those turned out differently when run:

- `--gpu-to-llvm` alone **does not** produce the launch call in this toolchain (LLVM/MLIR 18.1.3, Ubuntu's `mlir-opt-18`); the launch is lowered later, at LLVM IR translation time (below). Chapter 10's sentence naming `mgpuModuleLoad` was also slightly off: the real name is `mgpuModuleLoadJIT`.
- There is still no GPU runtime library on this machine, so a *stub* one is written instead.

## The host function, written by hand (and why)

Chapter 10's host code used plain `memref.alloc`, i.e. ordinary CPU memory, which a real device cannot read. This chapter's host function allocates device buffers with `gpu.alloc`, copies with `gpu.memcpy`, launches, copies the result back, and frees. **This function is hand-written, not generated from `mg.add`**: this book has no pass that inserts `gpu.alloc`/`gpu.memcpy` around a kernel, and writing one is not attempted here. The kernel module below it is Chapter 10's own `add_gpu.mlir` module, unchanged. The whole file:

```mlir
--8<-- "docs/part11/code/add_host_device.mlir"
```

Host function first (lines 4 to 20): three `gpu.alloc`s, two `gpu.memcpy`s in, the `gpu.launch_func` with a 2x1x1 grid and a 2x1x1 block, a host-side `memref.alloc` for the result, a `gpu.memcpy` back, and three `gpu.dealloc`s. The kernel module follows, exactly as in Chapter 10. `mlir-opt-18` parses and verifies the file as is.

## A real run of dead ends

Getting from this file to runtime calls took several real failures. They are recorded because each one cost time and none is obvious from the pass names. Chapter 12 later explained all three from MLIR's own source, and its `symptoms.sh` reproduces each one with saved output; the real outputs are shown here.

**1. `gpu-to-llvm` after `gpu-module-to-binary` crashes `mlir-opt-18`.** A pipeline of `nvvm-attach-target`, `convert-gpu-to-nvvm`, `gpu-module-to-binary{format=isa}`, `gpu-to-llvm`, then the usual `llvm` conversions died with a segmentation fault:

```text
--8<-- "docs/part12/code/symptoms/1_crash_after_binary.txt"
```

*(Update, added after Chapter 12: reading `GPUToLLVMConversion.cpp` at tag `llvmorg-18.1.3` established the cause: the launch pattern looks the kernel module up as a `gpu::GPUModuleOp`, which `gpu-module-to-binary` has already replaced, and dereferences the null result. See Chapter 12. The explanation in the next sentence is what was believed when this chapter was written.)* This chapter did not diagnose it beyond narrowing it down: with the `gpu.launch_func` line deleted the same `gpu-to-llvm` run does not crash, so the launch is involved. Treat "it crashes because the kernel `gpu.module` has become a `gpu.binary`" as a hypothesis consistent with the top frame, not a confirmed cause.

**2. `gpu-to-llvm` silently left `gpu.alloc` and `gpu.memcpy` alone.** With the launch removed, the pass "succeeded" but a `grep` for `mgpu` calls found none. The ops were still there:

```text
--8<-- "docs/part12/code/symptoms/2_survivors_without_async.txt"
```

and a later pass failed with `failed to legalize operation 'builtin.unrealized_conversion_cast'`. The fix was `gpu-async-region`, which rewrites these ops into their async form with `!gpu.async.token`s and stream handling. The evidence that async form is the requirement is that adding that one pass changed the output from no runtime calls to `mgpuMemAlloc`/`mgpuMemcpy`/`mgpuStreamCreate` (after it, the same listing is empty: `0` of these ops left). This chapter did not read the pass's source; Chapter 12 did.

**3. Putting `gpu-to-llvm` *before* the kernel conversion** got past the crash but failed verification:

```text
--8<-- "docs/part12/code/symptoms/3_operands_before_kernel_conversion.txt"
```

The pass had already expanded the three memref launch arguments into 23 scalars at the call site while the kernel still took 5 memref arguments. It is the same 2 + 3 x 7 = 23 expansion Chapter 10 found on the kernel side, now seen from the host side.

## What finally worked

MLIR's own packaged pipeline, run after `gpu-async-region`. The whole script (`pipeline.sh`):

```sh
--8<-- "docs/part11/code/pipeline.sh"
```

`--gpu-lower-to-nvvm-pipeline` appeared in `mlir-opt-18 --help` while writing Chapter 10; this is its first use. Its options in this version are named `cubin-*`; Chapter 10's standalone passes used `gpu-*` and pass-parameter names.

### Step 1: `gpu-async-region`

This is the real output of the first step (`async.mlir`, host function). Compare it with the hand-written version above:

```mlir
--8<-- "docs/part11/code/async.mlir:1:23"
```

Read the **token chain**: `%0 = gpu.wait async` creates an initial token; the first `gpu.alloc async [%0]` depends on it and returns `%asyncToken`; the next alloc depends on that; and so on through the two copies (`[%asyncToken_3]`, then `[%1]`) to the launch (`gpu.launch_func async [%2]`), whose token `%3` the host then waits on (`gpu.wait [%3]`). After the result is copied back the three deallocations chain the same way, ending in `gpu.wait [%8]`. The pass did not change *what* happens, only made each step's ordering explicit, in exactly the form `gpu-to-llvm`'s patterns accept.

### Step 2: after the packaged pipeline

After that pipeline, the output (`pipe_out.mlir`) contains all the host-side runtime calls **except** the launch: `mgpuMemAlloc` x3, `mgpuMemcpy` x3, `mgpuMemFree` x3, `mgpuStreamCreate`/`Synchronize`/`Destroy` x2 each, one `malloc`. The kernel is a `gpu.binary` holding Chapter 10's PTX as a string, and `gpu.launch_func` is still an MLIR op, now with a stream operand and the 23 expanded operands (line 17):

```mlir
--8<-- "docs/part11/code/pipe_out.mlir:17:17"
```

### Step 3: the launch is lowered at translation time

The remaining step is one Chapter 1 already used for a different purpose: `mlir-translate-18 --mlir-to-llvmir pipe_out.mlir -o host.ll`. The full translated file is 158 lines; here is what it does, in three pieces. First, create a stream, allocate three 32-byte device buffers (2 x 2 x 8 bytes) and copy the two inputs in:

```llvm
--8<-- "docs/part11/code/host.ll:12:17"
```

Then the launch itself, the part `gpu-to-llvm` did not produce:

```llvm
--8<-- "docs/part11/code/host.ll:112:117"
```

Reading it: load the embedded PTX as a module (optimization level 2); look up the kernel by name; **launch** with grid `x, y, z` = `2, 1, 1`, block `x, y, z` = `2, 1, 1`, shared memory `0`, on stream `%15`, with `%20` as an array of **23 pointers, one per kernel parameter**, a null `extra`, and the parameter count `23`; unload the module; synchronize and destroy the stream. The geometry matches Chapter 10's kernel exactly. Finally, copy the result back and release everything:

```llvm
--8<-- "docs/part11/code/host.ll:126:132"
```

The conclusion that the launch is lowered here rather than by `gpu-to-llvm` comes from this observation (the launch op is present in `pipe_out.mlir`, the runtime calls are present in `host.ll`), not from documentation.

## A stub device, and what it can and cannot prove

`host.ll` is real LLVM IR that calls functions this machine does not have. A real build would link NVIDIA's runtime wrapper library. With none available, a stub implements the same entry points on the CPU: "device memory" is `malloc`, copies are `memcpy`, and `mgpuLaunchKernel` runs a small C loop that reads the parameter-pointer array and does what the PTX does. Its source, in full (this is the version after Chapter 12 extended it to also accept a 5-parameter launch; the 23-parameter behavior described here is unchanged):

```c
--8<-- "docs/part11/code/stub_gpu_runtime.c"
```

For the 23-parameter layout it reads parameters 0 and 1 (loop step and lower bound) and 3, 10 and 17 (the three data pointers): the exact five parameters Chapter 10 found the PTX body actually loads. It computes `c[(block * step + lb) * 2 + thread] = a[i] + b[i]`, and it checks that the module handed to `mgpuModuleLoadJIT` really contains `.entry add_tensors_kernel`. It is linked with Chapter 8's **unmodified** harness:

```c
--8<-- "docs/part11/code/harness.c"
```

```bash
clang-18 -c host.ll -o host.o
clang-18 harness.c host.o stub_gpu_runtime.c -o add_tensors_stub_demo
./add_tensors_stub_demo
```

Real output (the stub's trace on stderr first, then the program's output):

```text
--8<-- "docs/part11/code/run_out.txt"
```

`[[6, 8], [10, 12]]` is the same answer Chapters 5 through 9 produced by other routes. The trace shows the sequence the host code is supposed to perform: three 32-byte device buffers, two copies in, a launch, one copy out.

**A negative control**, because a check that cannot fail proves nothing. `negative_control.sh` rebuilds the same program with the stub's kernel arithmetic line removed:

```sh
--8<-- "docs/part11/code/negative_control.sh"
```

```text
--8<-- "docs/part11/code/negative_control_out.txt"
```

It printed zeros, the contents of a fresh `malloc` (those bytes are not guaranteed to be zero; they happened to be). So the answer above does depend on the launch parameters being packed and read correctly.

**What this establishes:** the host-side glue is correct end to end: device allocation, host-to-device and device-to-host copies, launch geometry, the 23-parameter packing, and the descriptor handling for the returned memref, all through Chapter 8's own calling convention.

**What it does not establish:** that the PTX is correct, or that it assembles, or that it would run on any real GPU. The stub's kernel is **hand-written C that mirrors the PTX**, not an execution of it. Anything wrong in the PTX itself, or any difference between how a real driver packs `mgpuLaunchKernel`'s parameter array and how this stub reads it, is invisible to this check. A real run needs a GPU, the driver, the real runtime wrapper library, and `ptxas`; none exist in this sandbox.

## Reproducing this chapter

`pipeline.sh` runs every step above and was verified by running it in an empty directory and byte-comparing `pipe_out.mlir` and `host.ll` with the files in `code/`. Tools: `mlir-opt-18`, `mlir-translate-18`, `clang-18`; no packages beyond Chapter 10's. `run_out.txt` is the unedited output, and `negative_control.sh` (run after `pipeline.sh`, which produces `host.o`) regenerates the control. The three symptom files are produced by Chapter 12's `symptoms.sh`.

## What this chapter does not cite

As in Chapter 10, no `llvm-project` documentation was read for this chapter. Every claim about where a lowering step happens comes from running the pass and reading its output. In particular, the explanations for the three dead ends were, when this chapter was written, the most likely readings of what was observed, not verified root causes; Chapter 12 verified them from source.

## Chapter summary

This chapter built the host side of Chapter 10's kernel as far as a GPU-less sandbox allows. A hand-written host function wraps the kernel in `gpu.alloc`, `gpu.memcpy` and `gpu.dealloc`; `gpu-async-region` rewrites those into the async form MLIR 18's lowering requires; MLIR's own `--gpu-lower-to-nvvm-pipeline` produces the kernel binary and the host runtime calls; and `mlir-translate-18` turns the remaining `gpu.launch_func` into `mgpuModuleLoadJIT`, `mgpuModuleGetFunction`, `mgpuLaunchKernel` and `mgpuModuleUnload` calls with a 2x1x1 grid, a 2x1x1 block and 23 kernel parameters. Linked with Chapter 8's unmodified harness and a CPU stub runtime, the result prints `[[6, 8], [10, 12]]`, and a negative control with the stub's arithmetic removed does not. Three real dead ends are recorded with their outputs.

Deliberately out of scope, stated explicitly: the host function is hand-written (no pass generates it), the stub's "kernel" is C code mirroring the PTX rather than an execution of it, so nothing here shows the PTX is correct or even assembles, and the three dead ends were explained from MLIR's source only afterwards, in Chapter 12.

## Self-check questions

**1. `gpu-to-llvm` ran without error on the original host function and left `gpu.alloc` and `gpu.memcpy` in place. What fixed it, and why was the failure silent?**

Worked answer: `gpu-async-region` fixed it, by rewriting the ops into their async form with `!gpu.async.token`s. The failure was silent because the lowering patterns only match async operations and a pattern that does not match simply leaves the op alone; the first visible error came later, when a conversion pass hit an `unrealized_conversion_cast` it could not legalize. The evidence in this chapter is the before/after listing: nine `gpu.alloc`/`gpu.memcpy`/`gpu.dealloc` ops survive without the pass and none with it. Chapter 12 later read the pattern's source and found the explicit "Can convert only async version" test.

**2. The final `mgpuLaunchKernel` call ends in `i64 23`. What is that number, and what are the arguments before it?**

Worked answer: it is the number of kernel parameters, 23, the same expanded count as the kernel's own signature (2 index arguments plus 3 memrefs of seven scalars each). The arguments in order are the kernel function handle; the grid x, y, z (2, 1, 1); the block x, y, z (2, 1, 1); the shared-memory size (0); the stream; a pointer to an array of 23 pointers, one per kernel parameter; and a null `extra`. The grid and block match Chapter 10's kernel exactly.

**3. Where is `gpu.launch_func` actually turned into runtime calls in this toolchain, and how did the chapter find out?**

Worked answer: at LLVM IR translation time, in `mlir-translate-18`, not in `gpu-to-llvm`. The evidence is a before/after observation: after the packaged pipeline, the MLIR still contains a `gpu.launch_func` (now with a stream operand and the 23 expanded operands) and no launch runtime call, while the translated `host.ll` contains `mgpuModuleLoadJIT`, `mgpuLaunchKernel` and `mgpuModuleUnload`. The chapter reached this from the outputs, not from documentation.

**4. What does linking against the stub runtime establish, and what does it leave open?**

Worked answer: it establishes that the host glue is right: three device allocations of 32 bytes, two copies in, a launch with grid `(2,1,1)` and block `(2,1,1)`, the parameter array packed in the layout the stub reads, one copy out, and the memref descriptor returned correctly through Chapter 8's calling convention. It leaves open everything about the PTX: the stub's kernel is hand-written C mirroring the PTX's five loaded parameters and arithmetic, so a defect in the PTX, or a difference between how a real driver packs the parameter array and how the stub reads it, would be invisible.

**5. Why was the negative control worth running, and what exactly did it show?**

Worked answer: a check that cannot fail proves nothing. The same program was rebuilt with the stub's one arithmetic line removed. It printed zeros (the contents of a fresh `malloc`, which happened to be zero and are not guaranteed to be), not `6 8 / 10 12`. So the correct answer in the real run does depend on the launch being packed and executed correctly, rather than being produced by some other path.
