# 14. A Runtime Shape Check: Closing Chapter 13's Memory-Safety Hole

**What you will understand:** how to turn Chapter 13's silent out-of-bounds read into a loud, immediate abort, on both of this book's lowering paths, with no new pass and no cost for static programs. The chapter shows the helper code in full, the complete diff against Chapter 13, the generated IR before and after, and the real output of every test. Along the way: why a compile-time verifier cannot be enough once shapes are dynamic, what `cf.assert` is and how it reaches machine code, one crash that came from MLIR's lazy dialect loading (reproduced here from source, not just remembered), and one real weakness in how MLIR's own `cf.assert` reports its message.

**What you need to know first:** Chapter 13's dynamic-shape lowering (`memref.dim`, dynamic `memref.alloc`) and its recorded "known gap". New ground: `cf.assert` and `arith.cmpi`.

## The problem, restated with the real evidence

Chapter 13 ended with a call that should never have run to completion. `a` is a 2x3 matrix; `b` is declared 1x2 and its buffer holds only two doubles. The harness:

```c
--8<-- "docs/part13/code/harness_mismatch.c"
```

and what Chapter 13 recorded when it ran (the last two lines of its `run_out.txt`):

```text
--8<-- "docs/part13/code/run_out.txt:81:82"
```

The loop bounds come from `a` (2x3, six elements); the loads from `b` run off the end of its two-element buffer. The first two sums are right (`11 22`, those elements exist in both); the rest is whatever sat in memory beyond `b`. No verifier could have stopped this: the verifier sees *types*, and `tensor<?x?xf64>` plus `tensor<?x?xf64>` is compatible as types. Whether the two sizes agree is a fact about the values arriving at runtime, so the only place left to enforce it is the compiled code itself.

## Background: what `cf.assert` is

MLIR's `cf` (control-flow) dialect has an operation `cf.assert %condition, "message"`: if the `i1` condition is false at runtime, the program must stop. That is exactly the semantics wanted here: compute "do the two sizes match", assert it, and only then run the loop. How it reaches machine code was checked directly, before writing any dialect code, on a ten-line function that compares two dynamic sizes and asserts they are equal:

```mlir
--8<-- "docs/part14/code/probe_cf_assert.mlir"
```

Running the book's **existing** five-pass lowering on it (`--lower-affine --convert-scf-to-cf --convert-arith-to-llvm --finalize-memref-to-llvm --convert-func-to-llvm --reconcile-unrealized-casts`) produced this (`probe_cf_assert_lowered.mlir`; the long run of `insertvalue` lines is Chapter 1's memref-descriptor unpacking, and the part that matters is the end):

```mlir
--8<-- "docs/part14/code/probe_cf_assert_lowered.mlir:1:5"
```

```mlir
--8<-- "docs/part14/code/probe_cf_assert_lowered.mlir:31:40"
```

The assertion became an `icmp`, a conditional branch, and on the failing side a call to `puts` (print the message) followed by `abort`. **No new pass was needed**: Chapter 13 had predicted this lowering might be missing from the pipeline, and it is not. The lowering is evidently provided by `--convert-func-to-llvm`, the same pass that handles the `cf.br`/`cf.cond_br` that `scf-to-cf` emits; this chapter did not read that pass's source, only observed that no `--convert-cf-to-llvm` was needed (running it anyway produced the same two calls).

## The design, and what it deliberately skips

Before each dynamic `mg.add` loop, compare the two operands' sizes with `memref.dim` and `arith.cmpi eq`, and `cf.assert` the result. All of the logic lives in one helper, which both lowering paths call, so the two paths cannot drift apart on this. The helper in full (`DynamicShapes.h`, extending Chapter 13's version with `assertSameShape`):

```cpp
--8<-- "docs/part14/code/DynamicShapes.h"
```

The rules it implements:

- A dimension that is **static on both sides is skipped** (`continue`): the verifier already rejected any static mismatch, and a check there would be dead code. So static programs are untouched: the static `add_affine` output is still byte-identical to Chapter 10's stored file (`cmp`, test 1 below).
- A dimension that is **dynamic on at least one side is checked**, including the mixed case: `tensor<?x2xf64>` plus `tensor<3x2xf64>` gets exactly one check, on dimension 0; dimension 1 is static on both sides and skipped.
- `mg.transpose` needs no check: it has one operand, so there is nothing for its shape to disagree with.

### What the lowering now emits

The dynamic add after `--convert-mg-to-affine` (compare with Chapter 13's version, which went straight from the extents to the allocation):

```mlir
--8<-- "docs/part15/code/show/lower_dynamic-add-affine.mlir:3:20"
```

Reading it: lines 4 to 9 read the row extents of both operands, compare, assert; lines 10 to 15 do the same for columns; only then does the allocation (`memref.alloc(%dim_6, %dim_8)`) and the loop nest follow. The mixed case, where only dimension 0 is dynamic on one side:

```mlir
--8<-- "docs/part15/code/show/lower_mixed-add-one-check.mlir:3:12"
```

### The complete change

The unified diff against Chapter 13's files, all 145 lines, so nothing is hidden. It touches the helper, both lowerings, the `mg-opt` registration and the CMake link lines:

```diff
--8<-- "docs/part14/code/chapter14.diff"
```

## Two real problems on the way

### 1. Path B crashed on first use

The Path A version worked immediately. The same check from One-Shot Bufferize (Chapter 6's path) aborted `mg-opt`. This is reproduced from source: the chapter's tree was copied, **only** the line that loads the `cf` dialect was removed, and it was rebuilt and run on Chapter 13's `dyn_add.mlir` (`crash_without_loadDialect.txt`):

```text
--8<-- "docs/part14/code/crash_without_loadDialect.txt"
```

Adding `cf` to the `mg-opt` registry (needed anyway) made the dialect *known* but not *loaded*: MLIR loads dialects on demand, and nothing in that bufferization run had asked for `cf`. This chapter had assumed all registered dialects were already loaded; that assumption was wrong. Why `affine`, `arith` and `memref` never hit the same error in Chapters 5 and 6 was not investigated (a plausible but unchecked explanation is that other passes in those runs declared them as dependent dialects). The fix is one line in the external-model registration, next to the `attachInterface` calls:

```cpp
--8<-- "docs/part14/code/MgBufferizableOpInterfaceImpl.cpp:255:268"
```

Path A instead declares `cf` as a dependent and legal dialect in its own pass. The practical rule: **any op a bufferization model creates should have its dialect loaded by that model's registration**, rather than relying on something else having loaded it.

### 2. The abort works, but its message can vanish

Run with output on a terminal (or line-buffered) the program prints the message; run with stdout as a pipe or file it printed **nothing** before dying (test 9 below shows both). The lowered code in the probe above is the explanation: `call @puts(...)` then `call @abort()`. `puts` writes to *stdout*, which the C library fully buffers when it is not a terminal, and `abort()` does not flush stdio buffers. This is a property of how MLIR's `cf.assert` is lowered, observed here, not something this book chose. The safety property is intact either way (the program still dies, exit code 134, `SIGABRT`, before touching memory out of bounds); what is lost is the explanation, in exactly the situations (CI logs, captured output) where it would be most useful. A fix (lowering to a `fputs` on `stderr`, or flushing first) would be a custom conversion and is not done here.

## Building and testing it

The two scripts. `build.sh` assembles the compiler from the earlier chapters' files plus this chapter's overrides:

```sh
--8<-- "docs/part14/code/build.sh"
```

`run_tests.sh` runs eleven checks, reusing Chapter 13's inputs unchanged (plus one new harness for the mixed case):

```sh
--8<-- "docs/part14/code/run_tests.sh"
```

The one new harness, which takes the dynamic operand's row count as an argument so the same binary can be run with matching and mismatched sizes:

```c
--8<-- "docs/part14/code/harness_mixed.c"
```

### Real output, check by check

The complete, unedited output (`run_out.txt`):

```text
--8<-- "docs/part14/code/run_out.txt"
```

What each numbered section establishes:

| # | Check | Result |
|---|---|---|
| 1 | static output vs Chapter 10's stored file | `IDENTICAL`: the check costs static programs nothing |
| 2 | dynamic add, Path A | one `cmpi` + `cf.assert` per dimension, as shown above |
| 3 | mixed `?x2` + `3x2` | exactly one assert, for dimension 0 |
| 4 | Path B (One-Shot Bufferize) | the same two asserts from the same helper |
| 5, 6 | valid shapes, Paths A and B (including the column-major view) | compared **automatically** (`cmp`) with Chapter 13's recorded output: `MATCHES Chapter 13` |
| 7, 8 | mismatch (2x3 + 1x2), Paths A and B | message, `Aborted`, **exit code 134**; no garbage result printed |
| 9 | same, stdout is a pipe | **no message**, still exit code 134 (the buffering problem above) |
| 10, 11 | mixed `?x2` + `3x2`, matching then mismatched | `11 22 33 44 55 66`, then abort with exit code 134 |

In every abort case the harness never reached its `printf` of the result: the check fires before the loop, so no out-of-bounds load happens. This does not show the checks are **free**, only that this chapter did not measure their cost. By construction each check is two `memref.dim` reads, one comparison and one branch per dynamic dimension per `mg.add` call, outside the loop; whether LLVM's optimizer folds or hoists them further was not examined.

## What is still not safe

- **The check trusts the descriptors.** It compares the *sizes the caller declared*. A caller that passes a descriptor claiming 2x3 over a buffer holding two doubles is lying about memory, and no compiled check can detect that. The guarantee is "operand sizes agree", not "buffers are as large as their descriptors say".
- **Abort is the only response.** There is no error return or recoverable failure; a library embedding this compiled code gets a process death.
- **Only `mg.add` is checked,** the one op with two shaped operands. Allocation failure (`memref.alloc` returning null for a huge size), integer overflow in `rows * cols`, and negative sizes in a descriptor are not examined.
- **The GPU path has no check.** Chapters 10 through 12's kernels were static-shape; dynamic-shape GPU lowering was never attempted, so nothing here applies there.
- **Chapter 7's loop transforms on dynamic bounds** are still untested, as are any new passes' interactions with the assert (for example, whether `--canonicalize` or fusion preserves it across a transformation).
- **This chapter's own scripts still print results for a human to read.** *(Update, added after Chapter 15: the assertion-based suite now exists, and includes a test that mismatches only the columns, which this chapter's own scripts never exercised.)*

## Reproducing this chapter

```bash
cd docs/part14/code
./build.sh        # earlier chapters' files + this chapter's overrides -> ./build/mg-opt
./run_tests.sh    # eleven checks; output matches run_out.txt
```

Both were run from an empty state (build, tree and work directories deleted first) and `run_out.txt` is their unedited output. Every file and output above is embedded from the repository when the site is built, so this page cannot drift from the code it describes. As in Chapters 10 through 13, no documentation was consulted: every claim comes from running the code or reading it.

## Chapter summary

This chapter closed Chapter 13's out-of-bounds read for `mg.add`: before each dynamic add loop, the lowering reads both operands' sizes with `memref.dim`, compares them with `arith.cmpi`, and asserts with `cf.assert`, from one helper shared by both lowering paths. Dimensions static on both sides are skipped, so static output stays byte-identical to Chapter 10's, and a mixed `?x2` plus `3x2` add gets exactly one check. The book's existing five-pass lowering already turns `cf.assert` into `puts` plus `abort`, so no new pass was needed. Valid shapes matched Chapter 13's recorded output exactly on both paths, and every mismatch case aborted with exit status 134 before any out-of-bounds load. Two real problems are recorded: the bufferization path crashed because the `cf` dialect was registered but never loaded, and the assert's message is lost when stdout is a pipe.

Deliberately out of scope, stated explicitly: the check trusts the caller's descriptors, abort is the only response, only `mg.add` is guarded, the GPU path and loop transforms on dynamic bounds were not examined, and the runtime cost was not measured.

## Self-check questions

**1. Why can no compile-time check catch the 2x3-plus-1x2 call?**

Worked answer: the verifier only sees types, and `tensor<?x?xf64>` plus `tensor<?x?xf64>` is compatible as types. Whether the two sizes agree is a property of the values that arrive at runtime, so the only place left to enforce it is the compiled code, which is why the lowering emits a comparison and an assertion.

**2. Why does the helper skip a dimension that is static on both sides?**

Worked answer: the verifier already rejected any static mismatch, so a check there could never fire and would be dead code. Skipping it is also what keeps static programs untouched: the static add's lowering has no `cf.assert` and no `memref.dim`, and the `--convert-mg-to-affine` output for it is byte-identical to the file stored in Chapter 10.

**3. The bufferization path crashed on first use while the hand-written path worked. What was the cause, and what is the rule?**

Worked answer: One-Shot Bufferize's model created a `cf.assert`, but the `cf` dialect, though registered with `mg-opt`, had not been loaded into the context, and MLIR loads dialects on demand; the build aborted with "Building op `cf.assert` but it isn't known in this MLIRContext". The fix is one `ctx->loadDialect<cf::ControlFlowDialect>()` in the external-model registration. The rule: any op a bufferization model creates should have its dialect loaded by that model's registration instead of relying on something else having loaded it. Why `affine`, `arith` and `memref` never hit this was not investigated.

**4. Run through a pipe, the aborting program printed no message. Why, and does that weaken the safety property?**

Worked answer: the lowered code calls `puts` (stdout) then `abort()`. When stdout is not a terminal it is fully buffered, and `abort()` does not flush stdio buffers, so the message is discarded. The safety property is untouched, since the program still dies with exit status 134 (`SIGABRT`) before any out-of-bounds access; what is lost is the explanation, in exactly the cases (CI logs, captured output) where it is most needed. Under a terminal or line-buffered output the message appears.

**5. What does the check still not guarantee?**

Worked answer: it compares the sizes the caller declared in the descriptors. A caller whose descriptor claims 2x3 over a buffer of two doubles is lying about memory, and no compiled comparison can detect that. The guarantee is that the operand sizes agree, not that each buffer is as large as its descriptor claims; the response to a mismatch is process death, with no recoverable error.
