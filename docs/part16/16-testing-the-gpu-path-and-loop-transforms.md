# 16. Testing the GPU Path and the Loop Transforms

**What you will understand:** how to bring Chapters 7 and 10 through 12 under the same assertion-based suite Chapter 15 built, with no GPU required, and what such tests can and cannot tell you. Chapter 15 ended by listing these as untested; this chapter adds 12 tests (22 to 34) and checks, again, that they can fail.

**What you need to know first:** Chapter 15's suite and `lit.cfg.py`; Chapter 7's tiling and unrolling; Chapters 10 through 12's GPU recipe.

## What was added

| Group | New tests | What each pins down |
|---|---|---|
| `loops/` | 2 | `--affine-loop-tile="tile-size=1"` yields four nested loops (two tile loops, two point loops) with the right index swap; fully unrolling both loops and canonicalizing leaves **no** `affine.for` and no `affine.apply`, and the four add-and-store groups use exactly the constant indices Chapter 7 recorded |
| `gpu/` kernel (Ch. 10) | 3 | `mg.add` through to a `gpu.module` kernel (`gpu.launch_func`, `gpu.block_id x`, `gpu.thread_id x`); the `nvvm` lowering (`#nvvm.target<chip = "sm_70">`, `nvvm.kernel`, the special-register reads); real PTX with **23** kernel parameters, 64-bit index arithmetic, two global loads, one add, one store |
| `gpu/` options (Ch. 10, 12) | 2 | `index-bitwidth=32` gives `mad.lo.s32` and no `mul.lo.s64` while still declaring 23 parameters; `kernel-bare-ptr-calling-convention=1` gives **5** parameters |
| `gpu/` host (Ch. 11, 12) | 2 | the translated LLVM IR contains the whole runtime-call sequence, with `mgpuLaunchKernel(..., i64 2, i64 1, i64 1, i64 2, i64 1, i64 1, i32 0, ..., i64 23)`; with bare pointers the final count is `5` |
| `gpu/` toolchain | 2 | `clang-18` compiles the CUDA-style comparison kernel to PTX with **3** parameters; **a test that pins the known LLVM 18.1.3 crash** (below) |
| `execution/` | 1 | the lowered host code linked with Chapter 11's CPU stub runtime prints `6 8 / 10 12` for both the 23-parameter and the 5-parameter launch, and the stub's own trace confirms `grid=(2,1,1) block=(2,1,1)` and the parameter count |

Real run (`code/run_out_34.txt`): `34 tests, Passed: 34 (100.00%)`.

## One test pins a bug on purpose

Chapter 12 established that running `gpu-to-llvm` after `gpu-module-to-binary` segfaults `mlir-opt-18` in this toolchain. `gpu/pass-order-crash.mlir` asserts exactly that, with `not --crash`. It is unusual because **it is designed to start failing**: if a newer LLVM fixes the bug, the test goes red, and that is the signal to revisit Chapters 11 and 12, not a sign of a regression in this book. The file's own header says so. This is a deliberate trade: a test that documents a toolchain property instead of a book property, accepted because Chapters 11 and 12 rest on it.

## Two mistakes along the way

1. **A wrong expectation, not a compiler bug.** The first full run had 33 passes and 1 failure: `gpu/ptx-index32`. The test counted 23 parameters declared `.u64`, but with `index-bitwidth=32` the two index parameters are declared `.u32`, and only seven matched. The compiler was right and the test wrong; the pattern now accepts either width (`.u{{(32|64)}}`).
2. **A bug in the mutation tool itself, caught by luck of looking.** The first run of the recipe-mutation script (below) reported that mutation 1, changing `index-bitwidth=64` to `32`, **passed**: the test did not notice. The cause was my `sed` expression, written without slashes around its address, which `sed` parsed as an *insert* command that dumped junk lines into the test file; the mutation never changed the recipe. The tool had counted "the file differs" as "mutation applied". Two fixes: the expression was corrected, and the script now **rejects a mutation whose line count changed** (a substitution never should change it). After the fix, the same mutation fails the test, and its diff is exactly one line. The lesson is about this chapter's whole method: a mutation check that can silently apply the wrong mutation is itself an untested test.

## Can the new tests fail?

`recipe_mutation.sh` copies the suite, changes one thing in the copy, and runs the affected test. These tests pin *recipes and a stub runtime* rather than `mg` source, so the mutations edit those:

| # | Change | Result |
|---|---|---|
| 1 | `index-bitwidth=64` to `32` | **FAIL** (output differs) |
| 2 | target chip `sm_70` to `sm_80` | **FAIL** (see below) |
| 3 | bare-pointer option dropped, so 5 parameters become 23 | **FAIL** (output differs) |
| 4 | bare-pointer option added to the host test, so 23 becomes 5 | **FAIL** (output differs) |
| 5 | `gpu-map-parallel-loops` left out of the recipe | **FAIL** (see below) |
| 6 | `tile-size` 1 to 2 | **FAIL** (output differs) |
| 7 | the second full-unroll pass removed | **FAIL** (output differs) |
| 8 | the stub runtime's kernel computes `a - b` instead of `a + b` | **FAIL** (wrong numbers printed) |

All eight were caught. **Not all eight failures are equally informative**, which the table's "(see below)" marks: for mutations 2 and 5 the broken recipe produced *no output at all* (`FileCheck` reported its first pattern missing from an empty input), so those tests failed because the pipeline errored, not because a specific property changed. That is still a failure the suite would flag, but it proves only "this recipe still works", not "this specific line of output is still right". For 1, 3, 4, 6, 7 and 8 the pipeline ran and a specific value changed, which is the stronger evidence.

### The Chapter 15 checks, re-run with 34 tests

The older-build and source-mutation scripts from Chapter 15 were re-run unchanged against the larger suite (`older_out_34.txt`, `mutation_out_34.txt`). The **same tests fail**: 13 on Chapter 7's build and 6 on Chapter 13's, and the same three mutation results (1, 3, and 3 failures). All 12 new tests pass on both older builds. That is the expected result and also a limit worth stating: the new tests do not exercise anything the `mg` dialect gained in Chapters 13 and 14, so they cannot tell those builds apart; they pin the GPU and loop pipelines, which those builds share.

## What this does and does not establish

- **The PTX is checked as text.** The tests confirm that the compiler emits PTX containing particular instructions, parameter counts and targets. **The PTX was never assembled or run**: there is still no `ptxas`, no driver and no GPU here, so no test can say the kernel computes the right answer on hardware.
- **The stub-runtime test checks the host glue only.** Its "kernel" is C code mirroring the PTX (Chapter 11). Mutation 8 shows the test catches a wrong *stub*; it says nothing about the real PTX.
- **PTX text is a brittle thing to pin.** Register numbers are deliberately not matched (`%{{.*}}`), but instruction choice (`mul.lo.s64`, `mad.lo.s32`) and parameter counts are. A different LLVM could legitimately emit different instructions and break these tests without anything being wrong.
- **The old builds passing the new tests** means these tests guard recipes and toolchain behavior, not the book's own source, as noted above.
- **`cuda-comparison` needs `clang-18` with its CUDA support** (the `-x cuda` frontend); it ran here without the CUDA SDK, using the raw NVVM builtins, as in Chapter 10.

## Still not covered

- **No CI.** Unchanged since Chapter 15; the suite still runs only when someone runs it.
- **Chapter 1, 2 and 9 remain untested:** the original `scf.for` demonstration, the dialect's own build and `mg-opt` verifier-from-scratch checks, and the `ExecutionEngine` host program.
- **Dynamic-bound loop transforms** (Chapter 7 on `?` extents) are still unexamined; the new loop tests use the static fused example.
- **Chapters 10 through 12's `gpu-to-llvm`-before-binary ordering is tested only by its negative:** the crash test. The positive order is exercised through `--gpu-lower-to-nvvm-pipeline`, which runs it internally.

## Reproducing this chapter

```bash
cd docs/part15/code
./run_lit.sh              # 34 tests (needs ../../part14/code/build.sh first, and: pip install lit)
./recipe_mutation.sh      # the eight recipe/stub mutations -> recipe_mutation_out.txt
./older_builds.sh         # the 34-test suite against Chapter 7's and 13's builds -> older_out_34.txt
./mutation.sh             # Chapter 15's three source mutations -> mutation_out_34.txt
```

The `*_out*.txt` files are unedited outputs. As in Chapters 10 through 15, no documentation was consulted for any claim; each result above comes from running the commands.
