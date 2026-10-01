# 14. A Runtime Shape Check: Closing Chapter 13's Memory-Safety Hole

**What you will understand:** how to turn Chapter 13's silent out-of-bounds read into a loud, immediate abort, on both of this book's lowering paths, with no new pass and no cost for static programs. Along the way: why a compile-time verifier cannot be enough once shapes are dynamic, one crash that came from MLIR's lazy dialect loading, and one real weakness in how MLIR's own `cf.assert` reports its message.

**What you need to know first:** Chapter 13's dynamic-shape lowering and its `run_out.txt` section "KNOWN GAP". New ground: `cf.assert` and `arith.cmpi`.

## The problem, restated

Chapter 13 ended with this call, `a` a 2x3 matrix and `b` a 1x2 matrix holding two doubles, through the dynamic `mg.add`:

```text
result 2x3: 11 22 4 5 7 9
```

The loop bounds came from `a`; the loads from `b` ran off the end of its buffer. No verifier could have stopped this: the verifier only sees types, and `tensor<?x?xf64>` against `tensor<?x?xf64>` is compatible *as types*. Whether the two sizes agree is a fact about the values arriving at runtime, so the only place left to enforce it is the compiled code itself.

## The design, and what it deliberately skips

Before each dynamic `mg.add` loop, compare the two operands' sizes with `memref.dim` and `arith.cmpi eq`, and `cf.assert` the result. The rules, all in one helper (`assertSameShape` in `DynamicShapes.h`):

- A dimension that is **static on both sides is skipped**: the verifier already rejected any static mismatch, and a check there would be dead code. As a result, static programs are untouched: the static `add_affine` output is still **byte-identical to Chapter 10's** stored file (`cmp`, test 1).
- A dimension that is **dynamic on at least one side is checked**, including the mixed case: `tensor<?x2xf64>` + `tensor<3x2xf64>` gets exactly one check, on dimension 0 (test 3); dimension 1 is static on both sides and skipped.
- `mg.transpose` needs no check: it has one operand, so there is nothing for its shape to disagree with.

The emitted IR for the fully dynamic add (test 2):

```mlir
%0 = arith.cmpi eq, %dim, %dim_1 : index
cf.assert %0, "mg.add: operand shapes differ at runtime in dimension 0"
%1 = arith.cmpi eq, %dim_2, %dim_4 : index
cf.assert %1, "mg.add: operand shapes differ at runtime in dimension 1"
```

Both lowering paths call the same helper (Chapter 5's hand-written pattern and Chapter 6's bufferization model), so the two paths cannot drift apart on this. The unified diff against Chapters 13, 7 and the earlier files is `code/chapter14.diff` (145 lines).

## Checking the pipeline first: no new pass was needed

Chapter 13 said closing this hole "also needs to confirm the `cf` lowering is present in the five-pass pipeline." Checked directly before writing any dialect code, on a ten-line test function: the book's **existing** five-pass lowering (`--lower-affine --convert-scf-to-cf --convert-arith-to-llvm --finalize-memref-to-llvm --convert-func-to-llvm --reconcile-unrealized-casts`) already turns `cf.assert` into LLVM-dialect calls to `puts` and `abort`. The lowering is evidently provided by `--convert-func-to-llvm` (the same pass also lowers the `cf.br`/`cf.cond_br` that `scf-to-cf` emits; this chapter did not read its source to confirm that, only observed that no `--convert-cf-to-llvm` was needed). Running that extra pass anyway produced the same two calls.

## Two real problems on the way

1. **Path B crashed on first use.** The Path A version worked immediately. The same check from One-Shot Bufferize aborted `mg-opt` with `LLVM ERROR: Building op 'cf.assert' but it isn't known in this MLIRContext: the dialect may not be loaded`. Adding `cf` to the `mg-opt` registry (needed anyway) made it *known* but not *loaded*: MLIR loads dialects on demand, and nothing in that bufferization run had asked for `cf`. This chapter had assumed all registered dialects were already loaded; that assumption was wrong. Why `affine`, `arith` and `memref` never hit the same error in Chapters 5 and 6 was not investigated (a plausible but unchecked explanation is that other passes in those runs declared them as dependent dialects). The fix is one line in the external-model registration, `ctx->loadDialect<cf::ControlFlowDialect>()`, next to the `attachInterface` calls (Path A instead declares `cf` as a dependent and legal dialect in its own pass). The practical rule: **any op a bufferization model creates should have its dialect loaded by that model's registration**, rather than relying on something else having loaded it.
2. **The abort works, but its message can vanish.** Running the mismatch program with output on a terminal (or line-buffered) prints the message; run with stdout as a pipe or file, it printed **nothing** before dying (test 9). The generated code is `call @puts(...)` then `call @abort()`: `puts` writes to *stdout*, which is fully buffered when not a terminal, and `abort()` does not flush stdio buffers. This is a property of how MLIR's `cf.assert` is lowered, observed here, not something this book chose. The safety property is intact either way (the program still dies with exit code 134, `SIGABRT`, before touching memory out of bounds); what is lost is the explanation, in exactly the situations (CI logs, captured output) where it would be most useful. A fix (lowering to a `fputs` on `stderr`, or flushing first) would be a custom conversion and is not done here.

## Results

On the Chapter 13 test inputs, rebuilt from scratch:

| Test | Result |
|---|---|
| valid shapes through Path A (five `add`/`transpose` calls) | output **compared automatically** (`cmp`) with Chapter 13's recorded output: identical |
| valid shapes through Path B, plus the column-major strided view | identical to Chapter 13's recorded output |
| mismatch (2x3 + 1x2), Path A | abort, **exit code 134**, no garbage result printed |
| mismatch, Path B | abort, exit code 134 |
| mixed `?x2` + `3x2`, matching (`a` has 3 rows) | `11 22 33 44 55 66` |
| mixed `?x2` + `3x2`, mismatched (`a` has 2 rows) | abort, exit code 134 |

In every abort case the harness never reached its `printf` of the result: the check fires before the loop, so no out-of-bounds load happens. This does not show the checks were **free**, only that this chapter did not measure their cost. By construction each check is two `memref.dim` reads, one comparison and one branch per dynamic dimension per `mg.add` call, outside the loop; whether LLVM's optimizer folds or hoists them further was not examined.

## What is still not safe

- **The check trusts the descriptors.** It compares the *sizes the caller declared*. A caller that passes a descriptor claiming 2x3 over a buffer holding 2 doubles (the harness's `b` in Chapter 13 is honest about its 1x2 size) is lying about memory, and no compiled check can detect that. The guarantee is "operand sizes agree", not "buffers are as large as their descriptors say".
- **Abort is the only response.** There is no error return or recoverable failure; a library embedding this compiled code gets a process death.
- **Only `mg.add` is checked,** the one op with two shaped operands. Allocation failure (`memref.alloc` returning null for a huge size), integer overflow in `rows * cols`, and negative sizes in a descriptor are not examined.
- **The GPU path has no check.** Chapters 10 through 12's kernels were static-shape; dynamic-shape GPU lowering was never attempted, so nothing here applies there.
- **Chapter 7's loop transforms on dynamic bounds** are still untested, as are any new passes' interactions with the assert (for example, whether `--canonicalize` or fusion preserves it across a transformation).
- **Still no assertion-based test suite.** *(Update, added after Chapter 15: written there, with a test that mismatches only the columns, which this chapter's own scripts never exercised.)* `run_tests.sh` now does compare two outputs automatically and prints exit codes, which is more than Chapter 13's script, but it prints results for a human to read rather than failing on a mismatch. Real `lit`/`FileCheck` tests remain an open candidate.

## Reproducing this chapter

```bash
cd docs/part14/code
./build.sh        # earlier chapters' files + this chapter's overrides -> ./build/mg-opt
./run_tests.sh    # eleven checks; output matches run_out.txt
```

Both were run from an empty state (build, tree and work directories deleted first) and `run_out.txt` is their unedited output. Test inputs are Chapter 13's, referenced by relative path, plus one new harness (`harness_mixed.c`). As in Chapters 10 through 13, no documentation was consulted: every claim comes from running the code or reading it.
