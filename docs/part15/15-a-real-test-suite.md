# 15. A Real Test Suite: `lit`, `FileCheck`, and Proof That the Tests Can Fail

**What you will understand:** how to turn this book's "run it once and paste the output" scripts into an assertion-based regression suite that fails when behavior changes -- and, more important, how to *show* that it can fail. Chapters 12 through 14 each flagged the same gap ("no `lit`/`FileCheck` tests, no CI"); this chapter closes the first half of it. The second half (continuous integration) is not done here.

**What you need to know first:** Chapters 3 through 14's behavior. The suite tests what those chapters built; it adds no compiler features.

## The tools, and one deviation

MLIR's own tests use `lit` (a test runner) and `FileCheck` (pattern matching on output). This sandbox has `FileCheck-18` and `not-18` from the `llvm-18-tools` package, but **no `lit` for LLVM 18**: there is no apt package for it here (`apt-get install python3-lit` and `lit` both report "Unable to locate package"). `lit` was installed from PyPI instead, **version 23.1.2, which is not the toolchain's version (18.1.3)**. `lit` is a standalone Python test runner that only launches processes, so the mismatch is unlikely to matter, but it is a deviation, stated here rather than hidden.

## The suite: 22 tests in five groups

Each test is one `.mlir` file whose `// RUN:` lines say what to run and whose `// CHECK:` lines say what must appear. `lit.cfg.py` defines substitutions (`%mg-opt`, `%clang`, `%FileCheck`, `%not`, `%lower-to-llvm`, ...). Which `mg-opt` is tested comes from the `MG_OPT` environment variable, a choice that matters below.

| Group | Tests | What each one pins down |
|---|---|---|
| `verifier/` | 5 | static shape mismatch rejected; bad transpose shape rejected; rank 3 rejected; unranked rejected with an explicit message (Ch. 13); dynamic and mixed `?x2` + `3x2` accepted |
| `canonicalize/` | 4 | two constants fold into one (Ch. 3); `transpose(transpose(x))` folds; folds with dynamic extents when types match exactly; is left alone when types differ (Ch. 13's bug) |
| `lowering/` | 6 | static add lowers to constant-bound loops with **no** `cf.assert` and **no** `memref.dim`; dynamic add gets `memref.dim`, one assert per dimension, dynamic `alloc`; mixed add gets exactly one assert; dynamic transpose gets none; One-Shot Bufferize path matches both static and dynamic expectations |
| `loops/` | 1 | `--affine-loop-fusion` merges Chapter 7's add and transpose nests |
| `execution/` | 6 | compile to a native executable and run: static add (both paths), five dynamic shapes through one function (both paths), the column-major strided view, a row-count mismatch aborts, a **column-only** mismatch aborts, mixed static/dynamic matches and mismatches |

Real run (`code/run_out.txt`): `22 tests, Passed: 22 (100.00%)`, in about half a second wall-clock.

## A failure while writing it

The first full run had 19 passes and 2 failures, both in tests using `not --crash` (expect the program to die by signal). `lit`'s built-in `not` reported `'not': command not found` for that form. The verifier tests that wrote plain `not` had passed, but at that point a passing `not` test could not be told apart from a broken one, which is exactly why the next section exists. The fix was to stop relying on `lit`'s builtin and route every `not` through LLVM's own binary (`%not` = `not-18`, which supports `--crash`). After that, 22 of 22.

## Passing is not evidence: can the tests fail?

A suite that has only ever passed has not been shown to test anything. Two real checks, both scripted in `code/`:

### Check 1: the same tests against older builds

`older_builds.sh` points the **unchanged** suite at two earlier `mg-opt` builds. Every failure should be a feature that build lacks:

| Build | Result | Failures |
|---|---|---|
| Chapter 7's (assembled from Chapters 3, 5, 6, 7's files) | **13 failed, 9 passed** | all the dynamic-shape tests, the mixed-type canonicalizer test, the unranked test, every runtime-check test; **and `add-static-mismatch`** |
| Chapter 13's (dynamic shapes, no runtime check) | **6 failed, 16 passed** | exactly the six tests about the runtime check: both lowering tests for add (dynamic and mixed), the bufferize-dynamic test, and the three execution tests that expect an abort |

The nine tests that pass on the Chapter 7 build are the static ones plus the dynamic-extent transpose fold (Chapter 3's original pattern already handled the exact-type case correctly), which is the right result: that behavior never changed.

One failure there is *not* a missing feature, and is worth being honest about: `verifier/add-static-mismatch` fails on the Chapter 7 build because the error **wording** changed in Chapter 13 ("operands must have the same shape" became "operands must have compatible shapes"), not because the behavior (rejecting the program) changed. Pinning exact diagnostic text makes a test brittle in that way. It was kept deliberately: if the message changes, a human should look.

### Check 2: three deliberate bugs in the current source

`mutation.sh` copies Chapter 14's source tree three times, introduces one bug in each copy, builds it, and runs the suite:

| Mutation | Tests that failed |
|---|---|
| canonicalizer's exact-type guard removed (Chapter 13's bug returns) | **1**: `transpose-twice-dynamic-mixed` |
| runtime check covers only dimension 0 | **3**: both lowering tests that expect an assert for dimension 1, and `execution/mismatch-columns-aborts` |
| bufferization path forgets to emit the check | **3**: `bufferize-dynamic-add` and both abort tests |

Every mutation was caught, and by the tests aimed at it.

**The second mutation exposed a weakness in the suite as first written**, which is the main thing this check is for. With 21 tests, "check only dimension 0" was caught *only* by tests of the IR's structure; no native test ever mismatched the columns while the rows agreed, because Chapter 13's mismatch case differs in rows first. A runtime bug that structural tests happened to anticipate would have slipped past any native test. The 22nd test, `mismatch-columns-aborts` (2x3 + 2x2: rows equal, columns not), was added to close that, and the mutation was re-run: it now fails there too. (The numbers in the table above are from the final 22-test run.)

## What the suite does not cover

- **No CI.** Nothing runs these tests automatically on a push; they run when someone executes `./run_lit.sh`. A GitHub Actions workflow is the natural next step and is not written here, partly because it would need the MLIR 18 packages installed on the runner, which this sandbox cannot test.
- **Chapters 1, 2, 9, 10, 11 and 12 are untested here.** The dialect's own build (Chapter 2), the `ExecutionEngine` host (Chapter 9), and the GPU pipeline (Chapters 10 through 12) have no tests in this suite. The GPU lowering up to PTX needs no GPU, so it could be tested with `mlir-opt-18` and `FileCheck`; this chapter did not do it.
- **Loop transforms: one test.** Fusion is covered; tiling and unrolling (Chapter 7) are not.
- **Tests encode current behavior.** They show the compiler behaves as it does now, not that it is *correct*; the expected values were taken from outputs Chapters 3 through 14 had already validated by hand.
- **The abort message** is only checked under `stdbuf -oL`, because Chapter 14 found it is lost when stdout is a pipe: a test that failed on that would be testing the C library, not `mg`.
- **Diagnostics are pinned verbatim**, with the brittleness described above.

## Reproducing this chapter

```bash
pip install lit                        # lit 23.1.2 was used
../part14/code/build.sh                # builds the mg-opt under test
cd docs/part15/code
./run_lit.sh                           # the suite (22 tests)
./older_builds.sh                      # the same suite against Chapter 7's and Chapter 13's builds
./mutation.sh                          # the three mutations
```

`run_out.txt`, `older_out.txt` and `mutation_out.txt` are the unedited outputs. The `older_builds.sh` and `mutation.sh` runs were started from an empty `work/` directory. As in Chapters 10 through 14, no documentation was consulted for any claim here; the `not --crash` behavior, the `lit` version mismatch and every result above come from running the commands.
