# 16. Testing the GPU Path and the Loop Transforms

**What you will understand:** how to bring Chapter 7's loop transforms and Chapters 10 through 12's GPU pipeline under the assertion-based suite Chapter 15 built, with no GPU required. Every test is shown here **exactly as it exists in the repository, next to the real output it matches**, so you can see what each `CHECK` line is checking. Along the way the chapter explains the GPU concepts those checks depend on: what a launch grid is, why one matrix becomes seven kernel parameters, and how to read the PTX the compiler produces. It also checks, again, that the new tests can fail, and records two mistakes made while writing them.

**What you need to know first:** Chapter 15's suite and its `lit`/`FileCheck` basics (this chapter re-explains only the directives it uses); Chapter 7's tiling and unrolling; Chapters 10 through 12's GPU recipe.

## Where the suite stands

Chapter 15 left 22 tests and a list of what was not covered. This chapter adds 12, for 34:

| Group | New tests | What they pin down |
|---|---|---|
| `loops/` | `tiling`, `unroll-full` | Chapter 7's tiling and full unrolling |
| `gpu/` kernel | `kernel-outlining`, `nvvm-lowering`, `ptx-default` | Chapter 10: `mg.add` to a `gpu.module` kernel, to the `nvvm` dialect, to real PTX |
| `gpu/` options | `ptx-index32`, `ptx-bare-pointers` | `index-bitwidth=32`; `kernel-bare-ptr-calling-convention=1` |
| `gpu/` host | `host-runtime-calls`, `host-runtime-calls-bare` | Chapter 11/12: the `mgpu*` call sequence in the translated LLVM IR |
| `gpu/` toolchain | `cuda-comparison`, `pass-order-crash` | the CUDA-style kernel compiles; a known LLVM 18.1.3 crash is pinned |
| `execution/` | `gpu-host-with-stub-runtime` | the host glue run against a CPU stub runtime |

Real run (`code/run_out_34.txt`):

```text
--8<-- "docs/part15/code/run_out_34.txt"
```

## A short primer: FileCheck directives used here

Each test is an MLIR file whose `// RUN:` lines say what to execute (with `%`-substitutions defined in `lit.cfg.py`) and whose `// CHECK:` lines are patterns that the *output piped into FileCheck* must satisfy, **in order**:

| Directive | Meaning |
|---|---|
| `CHECK: text` | `text` must appear somewhere after the previous match |
| `CHECK-NEXT: text` | `text` must appear on the very next line |
| `CHECK-SAME: text` | `text` must appear on the same line as the previous match |
| `CHECK-NOT: text` | `text` must **not** appear between the surrounding matches |
| `CHECK-COUNT-n: text` | `text` must appear `n` times in a row |
| `CHECK-LABEL: text` | an anchor that resets the search, so one function's checks can't match another's |
| `{{regex}}` | a regular expression inside a pattern |
| `%[[NAME:regex]]` / `%[[NAME]]` | capture something once, require the same text later |

Registers and SSA names (`%0`, `%rd7`) differ between compiler versions, so the tests below match them with `{{.*}}` or captures and pin only what matters.

## Part 1: the loop transforms (Chapter 7)

### The input

Both loop tests start from Chapter 7's *fused* program: one 2x2 loop nest that adds two matrices element by element (with the transposed access Chapter 7 found) through a 1x1 temporary buffer.

```mlir
--8<-- "docs/part15/code/test/Inputs/fused.mlir"
```

### Tiling

The test:

```mlir
--8<-- "docs/part15/code/test/loops/tiling.mlir:1:8"
```

The real output of `mg-opt fused.mlir --affine-loop-tile="tile-size=1"` (`show/tile1.mlir`):

```mlir
--8<-- "docs/part15/code/show/tile1.mlir:8:21"
```

Reading it: tiling splits each of the two original loops into an **outer tile loop** (`%arg2`, `%arg3`, stepping through tiles) and an **inner point loop** (`%arg4`, `%arg5`) that walks the elements inside one tile. `#map(%arg2)` is `d0` and `#map1(%arg2)` is `d0 + 1`, so with a tile size of 1 each point loop runs over exactly `[i, i+1)`: a one-iteration loop. That is the point of using size 1 on a 2x2 example: the structure is visible without changing what is computed. The `CHECK-NEXT` chain asserts all four loops nest directly, and the captures (`%[[PJ:.*]]`) assert that the load still reads `[%arg5, %arg4]` (point-j, point-i) while the store writes `[%arg4, %arg5]`, so the tiled code keeps Chapter 7's index swap.

### Full unrolling

```mlir
--8<-- "docs/part15/code/test/loops/unroll-full.mlir:1:14"
```

Real output after `--affine-loop-unroll="unroll-full"` run twice (each run unrolls only the innermost loops, as Chapter 7 found) and `--canonicalize` (`show/unroll_full.mlir`):

```mlir
--8<-- "docs/part15/code/show/unroll_full.mlir"
```

The first `CHECK-NOT: affine.for` asserts no loop survives; `CHECK-NOT: affine.apply` asserts canonicalization removed the index arithmetic that unrolling introduced; then the four groups are checked in the order the output has them, with the exact constant indices. The final `CHECK-NOT: affine.for` after the last group guards against a loop reappearing at the end.

## Part 2: the GPU kernel (Chapter 10)

### Background: what the kernel is

A GPU launch runs the same function once per **thread**. Threads are grouped into **blocks**, and blocks into a **grid**. Here the grid is 2 blocks of 2 threads, and each thread computes **one element** of a 2x2 result: the block index picks the row and the thread index picks the column. The recipe that builds this from Chapter 4's loops is: prove the loops independent (`affine-parallelize`), turn them into `scf.parallel` (`lower-affine`), map the outer loop to blocks and the inner to threads (`gpu-map-parallel-loops`), build a launch (`convert-parallel-loops-to-gpu`), and move the body into its own module (`gpu-kernel-outlining`).

### `kernel-outlining`

```mlir
--8<-- "docs/part15/code/test/gpu/kernel-outlining.mlir"
```

The real output it matches (`show/kernel.mlir`, host function then kernel module):

```mlir
--8<-- "docs/part15/code/show/kernel.mlir:3:48"
```

The first `CHECK` pins the host side: a `gpu.launch_func` naming the kernel with a 3-D grid (`blocks in`) and a 3-D block (`threads in`); the unused y and z dimensions are all 1. The second pins the kernel module and the third its signature: two `index` arguments (the loop's step and lower bound, which the generated index arithmetic `block_id * step + lb` needs) and three `memref<2x2xf64>` operands. `gpu.block_id x` and `gpu.thread_id x` are the row and column. The `y`/`z` ids and the `grid_dim`/`block_dim` reads are generated but unused; they disappear later (see the PTX below).

### `nvvm-lowering`

```mlir
--8<-- "docs/part15/code/test/gpu/nvvm-lowering.mlir"
```

`nvvm-attach-target` stamps the module with the target chip (`sm_70`: an arbitrary Volta-class choice, since nothing here runs); `convert-gpu-to-nvvm` rewrites `gpu.block_id x` into the NVVM special-register read `nvvm.read.ptx.sreg.ctaid.x` (and `thread_id` into `tid.x`) and the body into the `llvm` dialect. Real excerpt (`show/nvvm.mlir`):

```mlir
--8<-- "docs/part15/code/show/nvvm.mlir:16:18"
```

```mlir
--8<-- "docs/part15/code/show/nvvm.mlir:42:46"
```

```mlir
--8<-- "docs/part15/code/show/nvvm.mlir:58:66"
```

Look at the kernel signature in the first excerpt: **23 parameters**, which is where the next test comes in.

### Why 23 parameters

A `memref<2x2xf64>` is not a bare pointer: at the calling-convention level (Chapter 1) it is a descriptor of an allocated pointer, an aligned pointer, an offset, two sizes and two strides, which is **seven** scalars. The kernel takes three memrefs plus two index arguments: 2 + 3 x 7 = 23. The kernel then spends its first instructions rebuilding descriptor structs it barely uses.

### `ptx-default`

```mlir
--8<-- "docs/part15/code/test/gpu/ptx-default.mlir"
```

`--gpu-module-to-binary="format=isa"` runs LLVM's NVPTX backend and stores the PTX as a hex-escaped string attribute; `%decode-ptx` (`decode_ptx.py`, from Chapter 10) turns that back into text. The real PTX the test matches (`show/ptx64.ptx`), header and first parameters:

```text
--8<-- "docs/part15/code/show/ptx64.ptx:1:16"
```

and the body:

```text
--8<-- "docs/part15/code/show/ptx64.ptx:38:67"
```

How to read the body (the instruction meanings below are PTX's, stated from the instruction names and this program's behavior; this chapter did not consult NVIDIA's PTX manual):

- Lines 41 to 48: load the kernel parameters it actually needs: `param_0` (the loop step), `param_1` (the lower bound), and the three **aligned data pointers** (`param_3`, `param_10`, `param_17`, one per matrix: the second slot of each seven-field group). `cvta.to.global` converts each generic address to a global-memory address.
- Lines 49 to 52: read `%ctaid.x` (block index) and `%tid.x` (thread index), widening each to 64 bits (`cvt.s64.s32`).
- Lines 53 to 58: the index arithmetic: `(block * step + lb)` is the row; `shl 1` multiplies by 2 (the row stride of a 2-column matrix); adding the thread index gives the element number; `shl 3` multiplies by 8 (bytes per `f64`); adding the base pointer gives the address.
- Lines 59 to 64: two `ld.global.f64` loads, one `add.rn.f64`, one `st.global.f64`. This is the whole computation.

The test's `CHECK-COUNT-23` followed by `CHECK-NOT` pins exactly 23 declared parameters (a pattern that matches the `.param` *declarations* but not the `ld.param` instructions in the body, which have a different spelling); `mul.lo.s64` pins the 64-bit index arithmetic; the load/add/store sequence pins the computation. Notice what the backend did **unasked**: of the 23 declared parameters the body loads only five, and the unused `block_id y/z`, `grid_dim` and `block_dim` reads are gone.

### The two options

```mlir
--8<-- "docs/part15/code/test/gpu/ptx-index32.mlir"
```

With `index-bitwidth=32` the index arithmetic is 32-bit (`show/ptx32.ptx`):

```text
--8<-- "docs/part15/code/show/ptx32.ptx:41:62"
```

`mad.lo.s32` (multiply-add) replaces the `mul.lo.s64`/`add.s64` pair, and the two index parameters are now declared **`.u32`**, which is why the test's parameter pattern is `.u{{(32|64)}}`. The parameter *count* stays 23: narrowing the index does not touch the descriptor ABI.

```mlir
--8<-- "docs/part15/code/test/gpu/ptx-bare-pointers.mlir"
```

`kernel-bare-ptr-calling-convention=1` (Chapter 12's finding) passes each memref as one raw pointer, which works only because every shape here is static. Real PTX header (`show/ptx_bare.ptx`):

```text
--8<-- "docs/part15/code/show/ptx_bare.ptx:11:18"
```

**Five parameters:** the step, the lower bound and three pointers. For scale, the CUDA-style comparison kernel below has three, because it hard-codes the loop bounds.

### The CUDA comparison

```mlir
--8<-- "docs/part15/code/test/gpu/cuda-comparison.mlir"
```

The source it compiles (`Inputs/cuda_add.cu`; raw NVVM builtins because no CUDA headers are installed) and the PTX `clang-18` produced (`show/cuda.ptx`):

```cuda
--8<-- "docs/part15/code/test/Inputs/cuda_add.cu"
```

```text
--8<-- "docs/part15/code/show/cuda.ptx:11:42"
```

Same memory traffic as the MLIR kernel (two global loads, one add, one store), three parameters, 32-bit index arithmetic.

## Part 3: the host side (Chapters 11 and 12)

### Background: the runtime-call sequence

A launch needs more than a kernel: device buffers are allocated and filled, the kernel module is loaded, the kernel is launched on a stream with a grid and block size and a parameter array, and everything is released. MLIR 18 lowers these to calls into a GPU runtime library. The input is the hand-written host function Chapter 11 introduced (`gpu.alloc`, `gpu.memcpy`, `gpu.launch_func`, `gpu.dealloc`), made async with `gpu-async-region` first because the lowering patterns only match async ops (Chapter 12 read that in MLIR's source):

```mlir
--8<-- "docs/part15/code/test/Inputs/add_host_device.mlir"
```

### `host-runtime-calls`

```mlir
--8<-- "docs/part15/code/test/gpu/host-runtime-calls.mlir"
```

The matching lines of the translated LLVM IR (`show/host.ll`): allocation and copies in, then the launch, then copy out and release:

```llvm
--8<-- "docs/part15/code/show/host.ll:12:17"
```

```llvm
--8<-- "docs/part15/code/show/host.ll:112:117"
```

```llvm
--8<-- "docs/part15/code/show/host.ll:126:132"
```

The launch call's arguments, in order: the function handle; grid `x, y, z` = `2, 1, 1`; block `x, y, z` = `2, 1, 1`; shared memory `0`; the stream; a pointer to an array of **kernel parameter pointers**; a null `extra`; and the parameter count, `23`. The test pins the grid, block and count exactly. `host-runtime-calls-bare` is the same test with the bare-pointer option and a final `i64 5`:

```mlir
--8<-- "docs/part15/code/test/gpu/host-runtime-calls-bare.mlir"
```

### `pass-order-crash`: a test that pins a bug

```mlir
--8<-- "docs/part15/code/test/gpu/pass-order-crash.mlir"
```

Chapter 12 established, from MLIR's source, why running `gpu-to-llvm` after `gpu-module-to-binary` segfaults `mlir-opt-18`: the launch pattern looks the kernel module up by type, and `gpu-module-to-binary` has already replaced it with a `gpu.binary`. This test asserts the crash with `%not --crash`. It is deliberately unusual: **it is designed to start failing.** If a newer LLVM fixes the bug the test turns red, and that is the signal to revisit Chapters 11 and 12, not a regression in this book. The test's header comment says so for whoever sees it fail. It documents a toolchain property rather than a book property, which is accepted here because those chapters rest on it.

### `gpu-host-with-stub-runtime`

There is no GPU runtime library on this machine, so Chapter 11 wrote a CPU stand-in. Its source, in full:

```c
--8<-- "docs/part15/code/test/Inputs/stub_gpu_runtime.c"
```

and the test that links the lowered host code with it, once with the default 23-parameter launch and once with 5:

```mlir
--8<-- "docs/part15/code/test/execution/gpu-host-with-stub-runtime.mlir"
```

The test checks both the printed answer (`6 8 / 10 12`) and the stub's own trace on stderr (`grid=(2,1,1) block=(2,1,1) nparams=23` or `5`). **This tests the host glue only.** The stub's "kernel" is C that mirrors the PTX, not an execution of it.

## Two mistakes along the way

**1. A wrong expectation, not a compiler bug.** The first full run had 33 passes and 1 failure, `gpu/ptx-index32`. The test counted 23 parameters all declared `.u64`; with `index-bitwidth=32` the two index parameters are `.u32`, and only seven lines matched:

```text
ptx-index32.mlir:4:20: error: CHECK-COUNT: expected string not found in input (7 out of 23)
```

The compiler was right and the test was wrong. The pattern now accepts either width (`.u{{(32|64)}}`).

**2. A bug in the mutation tool itself.** Writing the mutation script below, mutation 1 (change `index-bitwidth=64` to `32`) was reported as **passing**: the test had not noticed. The cause was a `sed` expression written as `'index-bitwidth=64/s/64/32/'`, with no slashes around the address. `sed` parsed it as an *insert* command, so instead of substituting it added a junk line of text after every line of the test file. Diffing the "mutated" copy against the original showed:

```text
0a1
> ndex-bitwidth=64/s/64/32/
1a3
> ndex-bitwidth=64/s/64/32/
...
```

The recipe was never changed, and the tool had counted "the file differs" as "the mutation applied". Two fixes: the expression was corrected (`'/index-bitwidth=64/s/64/32/'`), and the script now **rejects any mutation that changes the line count**, since a substitution never should. After the fix the same mutation fails the test and its diff is exactly one line. The lesson is about the whole method: a mutation check that can silently apply the wrong mutation is itself an untested test.

## Can the new tests fail?

`recipe_mutation.sh` copies the suite, changes one thing in the copy, and runs only the affected test. These tests pin recipes and a stub runtime rather than `mg` source, so the mutations edit those:

```sh
--8<-- "docs/part15/code/recipe_mutation.sh"
```

Real output:

```text
--8<-- "docs/part15/code/recipe_mutation_out.txt"
```

All eight are caught, but they are not equally informative. For mutations 2 (a different chip) and 5 (a recipe missing `gpu-map-parallel-loops`) the broken recipe produced **no output at all**: `FileCheck` reported its first pattern missing from an empty input. Those tests failed because the pipeline errored, which proves only "this recipe still works", not "this specific line of output is still right". For mutations 1, 3, 4, 6, 7 and 8 the pipeline ran and a specific value changed (the index width, the parameter count, the tile structure, the unrolled loops, the printed numbers), which is the stronger evidence.

### Chapter 15's checks, re-run with 34 tests

The older-build comparison and the three source mutations from Chapter 15 were re-run unchanged against the larger suite. Older builds (`older_out_34.txt`):

```text
--8<-- "docs/part15/code/older_out_34.txt"
```

Source mutations (`mutation_out_34.txt`):

```text
--8<-- "docs/part15/code/mutation_out_34.txt"
```

The **same tests fail** as in Chapter 15 (13 on Chapter 7's build, 6 on Chapter 13's, and the same three mutation results), and all 12 new tests pass on both older builds. That is expected, and also a limit worth stating: the new tests exercise the GPU and loop pipelines, which those builds share, so they cannot tell those builds apart. They guard recipes and toolchain behavior, not the dynamic-shape features of Chapters 13 and 14.

## What this does and does not establish

- **The PTX is checked as text.** The tests confirm that the compiler emits PTX with particular instructions, parameter counts and targets. **The PTX was never assembled or run**: there is no `ptxas`, driver or GPU here, so no test can say the kernel computes the right answer on hardware.
- **The stub-runtime test checks the host glue only.** Mutation 8 shows it catches a wrong *stub* (`a - b` instead of `a + b`); it says nothing about the real PTX.
- **PTX text is a brittle thing to pin.** Register numbers are not matched, but instruction choice (`mul.lo.s64`, `mad.lo.s32`) and parameter counts are. A different LLVM could emit different, equally correct instructions and break these tests with nothing wrong.
- **`cuda-comparison` needs `clang-18`'s CUDA frontend.** It ran here without the CUDA SDK, using raw NVVM builtins, as in Chapter 10.
- **No CI.** The suite still runs only when someone runs it.
- **Chapters 1, 2 and 9 remain untested:** the original `scf.for` demonstration, the dialect's own build, and the `ExecutionEngine` host program.
- **Dynamic-bound loop transforms** (Chapter 7 on `?` extents) are unexamined; the new loop tests use the static fused example. *(Update, added after Chapter 17: now examined and tested there, taking the suite to 42 tests.)*

## Reproducing this chapter

```bash
cd docs/part15/code
./run_lit.sh              # 34 tests (needs ../../part14/code/build.sh first, and: pip install lit)
./show.sh                 # regenerates every output shown on this page under show/
./recipe_mutation.sh      # the eight recipe/stub mutations
./older_builds.sh         # the 34-test suite against Chapter 7's and 13's builds
./mutation.sh             # Chapter 15's three source mutations
```

Every file and output shown above is embedded from the repository when the site is built, so this page cannot drift from the code it describes (a missing file fails the build). As in Chapters 10 through 15, no documentation was consulted for any claim; each result comes from running the commands.

## Chapter summary

This chapter extended the suite from 22 to 34 tests, covering Chapter 7's tiling and full unrolling and the whole GPU path of Chapters 10 through 12 without a GPU: kernel outlining, NVVM lowering, real PTX (23 parameters by default, 5 with bare pointers, 3 for the CUDA-style kernel), the `index-bitwidth` option, the host runtime-call sequence, the CUDA comparison compile, and a run of the lowered host code against a CPU stub runtime. One test deliberately pins Chapter 12's LLVM 18.1.3 crash and is designed to start failing when a newer LLVM fixes it. Eight recipe and stub mutations were all caught, though two only because the broken recipe produced no output. Two mistakes are recorded: a wrong expectation (the index parameters become `.u32` at 32-bit width) and a bug in the new mutation script itself (a `sed` expression that inserted lines instead of substituting, so a mutation had never been applied).

Deliberately out of scope, stated explicitly: the PTX is checked only as text and has never been assembled or run, the stub test checks host glue only, pinning PTX instruction choices is brittle across LLVM versions, no CI runs the suite, and Chapters 1, 2 and 9 are still untested.

## Self-check questions

**1. `gpu/pass-order-crash.mlir` is designed to start failing. Why write such a test, and what should someone do when it fails?**

Worked answer: it pins a property of the toolchain, the LLVM 18.1.3 segmentation fault when `gpu-to-llvm` runs after `gpu-module-to-binary`, that Chapters 11 and 12 depend on. If a newer LLVM fixes the bug, the test goes red. That is the signal to revisit those two chapters and the recipe, not a regression in this book, and the test's header says so for whoever sees it fail.

**2. Eight recipe mutations were all caught, but the chapter calls two of the failures weaker evidence. Which two, and why?**

Worked answer: mutation 2 (a different chip) and mutation 5 (a recipe missing `gpu-map-parallel-loops`). In both the broken recipe produced no output at all, so `FileCheck` reported its first pattern missing from an empty input. Those tests failed because the pipeline errored, which shows only that the recipe still works. For the other six (index width, parameter count in two tests, tile structure, unrolled loops, printed numbers) the pipeline ran and a specific value changed, which is the stronger evidence.

**3. What went wrong the first time mutation 1 ran, and what guard was added?**

Worked answer: the `sed` expression `'index-bitwidth=64/s/64/32/'` had no slashes around its address, so `sed` read it as an insert command and added a junk line after every line of the test file instead of substituting. The recipe was never changed, so the unchanged test passed, and the script had treated "the file differs" as "the mutation applied". The expression was corrected and the script now rejects any mutation that changes the file's line count, since a substitution never should.

**4. All 12 new tests pass on the Chapter 7 and Chapter 13 builds. What does that tell you about what they test?**

Worked answer: they pin the GPU and loop pipelines and the toolchain's behavior, which those builds share, not the dynamic-shape features added in Chapters 13 and 14. That is why they cannot tell those builds apart, and it is expected: the earlier 22 tests are the ones that distinguish them.

**5. What does the stub-runtime execution test tell you, and what does it not?**

Worked answer: it checks the host glue: the program prints `6 8 / 10 12` with both the 23-parameter and the 5-parameter launch, and the stub's trace confirms the grid, block and parameter count. It does not execute the PTX, because the stub's kernel is C code written to mirror it. Mutation 8, changing the stub's `a + b` to `a - b`, shows the test catches a wrong stub, which is a statement about the test, not about the real kernel.
