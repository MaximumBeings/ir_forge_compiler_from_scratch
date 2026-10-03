# 15. A Real Test Suite: `lit`, `FileCheck`, and Proof That the Tests Can Fail

<p style="text-align:center"><img src="../assets/goats/ch-15.svg" alt="Mountain goats on the mountain in black and white at dusk" style="max-width:100%;height:auto;border-radius:6px"></p>

**What you will understand:** how to turn this book's "run it once and paste the output" scripts into an assertion-based regression suite that fails when behavior changes, and, more important, how to *show* that it can fail. Every one of the suite's 22 original tests is printed here exactly as it exists in the repository, **next to the real output it checks**, so you can see what each pattern is matching and why. Chapters 12 through 14 each flagged the same gap ("no `lit`/`FileCheck` tests, no CI"); this chapter closes the first half of it. Continuous integration is not done here.

**What you need to know first:** Chapters 3 through 14's behavior. The suite tests what those chapters built; it adds no compiler features.

!!! tip "Compile and run"
    Every command, listing and output on this page is reproduced by the commands in [Reproducing this chapter](#reproducing-this-chapter) at the bottom of the page, which also lists what must be built first. The chain of builds is in [Getting Started](../getting-started.md#which-build-does-each-chapter-need).


!!! note "Why this page shows FAIL lines, and why that is good"
    Parts of this page come from **negative controls**: the same tests run against an *older* build, or against *deliberately broken* code (a "mutation"). In those runs a **FAIL is the expected, wanted result**: it means a test noticed the problem, which is how we know the tests are worth anything. What would be wrong is the opposite, a deliberately broken build that passes everything. The **baseline** (the unmodified current build) must always show every test passing, and it does. Each script that does this says so in its own header and prints a reminder at the top of its output.

## Why a test suite, and why this kind

Chapters 3 through 14 each ended with a pasted output, produced by a command run once. That proves the command worked *then*. It does not stop the next change from quietly breaking it, and two of the chapters already contain bugs found only later (Chapter 13 fixed a canonicalizer that produced invalid IR; Chapter 14 closed an out-of-bounds read). A test suite turns each pasted output into a check that runs again and **fails loudly** when the behavior changes.

MLIR's own project uses two tools for exactly this, and so does this suite:

- **`lit`** discovers test files, runs the shell commands written in each one's `// RUN:` lines, and reports pass or fail by exit status.
- **`FileCheck`** reads text on its standard input and checks it against `// CHECK:` patterns written in the same test file. A test is "run the compiler, pipe its output into FileCheck".

## How `lit` finds and runs a test

`lit.cfg.py` tells `lit` what a test is (a `.mlir` file), where to run it, and which `%`-names to substitute inside `RUN:` lines. The suite's, in full:

```python
--8<-- "docs/part15/code/test/lit.cfg.py"
```

The one design decision worth noticing is `MG_OPT`: **which `mg-opt` binary is tested is an environment variable**, not a constant. That is what lets the same suite be pointed at older builds later in this chapter to show the tests can fail. Each test gets its own scratch name (`%t`), so tests cannot read each other's files.

The launcher script is three lines of real logic:

```sh
--8<-- "docs/part15/code/run_lit.sh"
```

### The tools, and one deviation

This sandbox has `FileCheck-18` and `not-18` from the `llvm-18-tools` package, but **no `lit` for LLVM 18**: `apt-get install python3-lit` and `apt-get install lit` both report "Unable to locate package". `lit` was installed from PyPI instead: **version 23.1.2, which is not the toolchain's version (18.1.3)**. `lit` is a standalone Python test runner that only launches processes, so the mismatch is unlikely to matter, but it is a deviation, stated rather than hidden.

## A FileCheck primer

Each `CHECK` pattern must be found in the piped output **in order**:

| Directive | Meaning |
|---|---|
| `CHECK: text` | `text` must appear somewhere after the previous match |
| `CHECK-NEXT: text` | `text` must appear on the very next line |
| `CHECK-SAME: text` | `text` must appear on the same line as the previous match |
| `CHECK-NOT: text` | `text` must **not** appear between the surrounding matches |
| `CHECK-COUNT-n: text` | `text` must appear `n` times in a row |
| `CHECK-LABEL: text` | an anchor that resets the search, so one function's checks cannot match another's |
| `{{regex}}` | a regular expression inside a pattern |
| `%[[NAME:regex]]`, `%[[NAME]]` | capture text once, require the same text later |

SSA value names (`%0`, `%dim_2`) differ between compiler versions, so the tests below match them with `{{.*}}` and pin only what matters.

## The suite: 22 tests in five groups

| Group | Tests | What each one pins down |
|---|---|---|
| `verifier/` | 5 | static shape mismatch rejected; bad transpose shape rejected; rank 3 rejected; unranked rejected with an explicit message; dynamic and mixed shapes accepted |
| `canonicalize/` | 4 | two constants fold; transpose-of-transpose folds; folds with dynamic extents when types match exactly; is left alone when types differ |
| `lowering/` | 6 | static add lowers with no runtime check; dynamic add gets extents, a check per dimension and a dynamic allocation; a mixed add gets exactly one check; transpose gets none; the One-Shot Bufferize path matches |
| `loops/` | 1 | `--affine-loop-fusion` merges Chapter 7's two loop nests |
| `execution/` | 6 | compile to native code, run, check output and exit status |

Real run (`code/run_out.txt`, recorded when the suite had 22 tests; Chapter 16 grows it to 34):

```text
--8<-- "docs/part15/code/run_out.txt"
```

### Group 1: the verifier

A verifier is the dialect's own check that an operation is well formed (Chapter 3). Each test feeds a deliberately bad program to `mg-opt` and checks the diagnostic. The `%not` in front means "this command must **fail**", and `2>&1` sends the error text into FileCheck.

```mlir
--8<-- "docs/part15/code/test/verifier/add-static-mismatch.mlir"
```

The real output the pattern matches (`show/verify_add-static-mismatch.txt`):

```text
--8<-- "docs/part15/code/show/verify_add-static-mismatch.txt"
```

A static mismatch (`2x2` plus `2x3`) must die at compile time. The pattern pins the full message including both types, which makes the test strict about wording (see the end of this chapter). The other three rejection tests follow the same shape:

```mlir
--8<-- "docs/part15/code/test/verifier/transpose-bad-shape.mlir"
```

```text
--8<-- "docs/part15/code/show/verify_transpose-bad-shape.txt"
```

```mlir
--8<-- "docs/part15/code/test/verifier/transpose-rank3.mlir"
```

```text
--8<-- "docs/part15/code/show/verify_transpose-rank3.txt"
```

```mlir
--8<-- "docs/part15/code/test/verifier/unranked-rejected.mlir"
```

```text
--8<-- "docs/part15/code/show/verify_unranked-rejected.txt"
```

The last one matters for a reason Chapter 13 found: the original verifier cast an unranked tensor to a ranked type without checking, which in a release build happened to print a plausible message by luck. This test pins the explicit diagnostic that replaced it. The fifth test is the opposite direction: programs that **must be accepted**.

```mlir
--8<-- "docs/part15/code/test/verifier/dynamic-accepted.mlir"
```

with `CHECK-LABEL` keeping each function's checks to its own function. The real output, printed back unchanged:

```mlir
--8<-- "docs/part15/code/show/verify_dynamic-accepted.mlir"
```

### Group 2: the canonicalizer

Canonicalization (Chapter 3) rewrites a program into a simpler equivalent one. These tests pin what it must do and, equally, what it must **not** do.

```mlir
--8<-- "docs/part15/code/test/canonicalize/fold-constant-add.mlir"
```

```mlir
--8<-- "docs/part15/code/show/canon_fold-constant-add.mlir"
```

The two constants and the add are gone, replaced by one constant holding the sum (`CHECK-NOT: mg.add` asserts the add did not survive). The regular expression `{{\[\[}}` is just an escaped literal `[[`. The transpose pair:

```mlir
--8<-- "docs/part15/code/test/canonicalize/transpose-twice.mlir"
```

```mlir
--8<-- "docs/part15/code/show/canon_transpose-twice.mlir"
```

The next two are the pair that guard Chapter 13's bug. With dynamic extents the rewrite still fires when its replacement has exactly the right type:

```mlir
--8<-- "docs/part15/code/test/canonicalize/transpose-twice-dynamic-exact.mlir"
```

```mlir
--8<-- "docs/part15/code/show/canon_transpose-twice-dynamic-exact.mlir"
```

but it must be left alone when it would change a type (it once produced invalid IR here):

```mlir
--8<-- "docs/part15/code/test/canonicalize/transpose-twice-dynamic-mixed.mlir"
```

```mlir
--8<-- "docs/part15/code/show/canon_transpose-twice-dynamic-mixed.mlir"
```

### Group 3: the lowerings

These check the *shape* of the IR the two lowering paths produce. The first is the baseline: a static add must lower to constant-bound loops with **no** runtime machinery.

```mlir
--8<-- "docs/part15/code/test/lowering/static-add-affine.mlir"
```

```mlir
--8<-- "docs/part15/code/show/lower_static-add-affine.mlir"
```

The two `CHECK-NOT` lines are the point: the dynamic-shape work of Chapters 13 and 14 must cost static programs nothing. The dynamic add, where each dimension's size is read at runtime and compared before the loop:

```mlir
--8<-- "docs/part15/code/test/lowering/dynamic-add-affine.mlir"
```

```mlir
--8<-- "docs/part15/code/show/lower_dynamic-add-affine.mlir"
```

`CHECK-NEXT` asserts each `cf.assert` directly follows its comparison. The mixed case, where only the dimension that is dynamic is checked:

```mlir
--8<-- "docs/part15/code/test/lowering/mixed-add-one-check.mlir"
```

```mlir
--8<-- "docs/part15/code/show/lower_mixed-add-one-check.mlir"
```

and the transpose, which has one operand and therefore nothing to compare, with the result's extents swapped (`%c1` then `%c0`):

```mlir
--8<-- "docs/part15/code/test/lowering/dynamic-transpose-no-check.mlir"
```

```mlir
--8<-- "docs/part15/code/show/lower_dynamic-transpose.mlir"
```

The last two cover Chapter 6's other path, One-Shot Bufferize, which must produce the same structure. Note its function arguments are strided memref types (Chapter 6's finding), and the test pins that:

```mlir
--8<-- "docs/part15/code/test/lowering/bufferize-dynamic-add.mlir"
```

```mlir
--8<-- "docs/part15/code/show/lower_bufferize-dynamic-add.mlir"
```

```mlir
--8<-- "docs/part15/code/test/lowering/bufferize-static-add.mlir"
```

```mlir
--8<-- "docs/part15/code/show/lower_bufferize-static-add.mlir"
```

### Group 4: loop transforms

One test, for Chapter 7's fusion (Chapter 16 adds tiling and unrolling). The header of the test, then the real output of `--affine-loop-fusion` on Chapter 7's program:

```mlir
--8<-- "docs/part15/code/test/loops/fusion.mlir:1:6"
```

```mlir
--8<-- "docs/part15/code/show/fusion.mlir"
```

Four loops (two nests of two) became one nest of two: `CHECK`/`CHECK-NEXT` pin the nested pair and the trailing `CHECK-NOT: affine.for` pins that no further loop remains.

### Group 5: running the compiled program

The strongest tests compile to a native executable and run it. This is a pipeline of `RUN:` lines, each one a step Chapters 4 through 8 introduced: lower with `mg-opt`, translate to LLVM IR, compile, link a C harness, run, and pipe the program's output into FileCheck. The static case, on both lowering paths:

```mlir
--8<-- "docs/part15/code/test/execution/static-add-runs.mlir"
```

The two real outputs (`show/exec_static-path-A.txt` and `-B.txt`):

```text
--8<-- "docs/part15/code/show/exec_static-path-A.txt"
```

```text
--8<-- "docs/part15/code/show/exec_static-path-B.txt"
```

The dynamic case: one compiled function, five different non-square shapes, both paths.

```mlir
--8<-- "docs/part15/code/test/execution/dynamic-shapes-run.mlir"
```

```text
--8<-- "docs/part15/code/show/exec_dynamic-path-A.txt"
```

The harness that makes those calls (`Inputs/dyn_harness.c`) builds the rank-2 memref descriptor Chapter 8 introduced, with sizes chosen at runtime:

```c
--8<-- "docs/part15/code/test/Inputs/dyn_harness.c"
```

The column-major view only the bufferization path's strided types can honor:

```mlir
--8<-- "docs/part15/code/test/execution/strided-view.mlir"
```

```text
--8<-- "docs/part15/code/show/exec_dynamic-path-B-strided.txt"
```

The two runtime-mismatch tests expect the program to **abort**. `%not --crash` means "must die from a signal", and the test's last `RUN:` shows the explanatory message by running under `stdbuf -oL` (line-buffered), because Chapter 14 found the message is lost when stdout is a pipe:

```mlir
--8<-- "docs/part15/code/test/execution/mismatch-aborts.mlir"
```

```text
--8<-- "docs/part15/code/show/exec_mismatch-rows.txt"
```

The second one mismatches **only the columns** (2x3 plus 2x2, rows equal). It was added after the failure-injection check below exposed that no native test covered that case:

```mlir
--8<-- "docs/part15/code/test/execution/mismatch-columns-aborts.mlir"
```

```text
--8<-- "docs/part15/code/show/exec_mismatch-columns.txt"
```

```c
--8<-- "docs/part15/code/test/Inputs/mismatch_cols_harness.c"
```

And the mixed static/dynamic case, matching sizes then mismatched:

```mlir
--8<-- "docs/part15/code/test/execution/mixed-static-dynamic.mlir"
```

```text
--8<-- "docs/part15/code/show/exec_mixed.txt"
```

## A failure while writing it

The first full run had 19 passes and 2 failures, both tests using `not --crash`. `lit`'s built-in `not` printed:

```text
'not': command not found
```

for that form. The verifier tests that wrote plain `not` had passed, but at that point a passing `not` test could not be told apart from a broken one, which is exactly why the next section exists. The fix was to stop relying on `lit`'s builtin and route every `not` through LLVM's own binary: `%not` is defined as `not-18` in `lit.cfg.py` above, and `not-18` supports `--crash`. After that, 22 of 22.

## Passing is not evidence: can the tests fail?

A suite that has only ever passed has not been shown to test anything. Two checks, both scripted.

### Check 1: the same tests against older builds

`older_builds.sh` points the **unchanged** suite at two earlier `mg-opt` builds. Every failure should be a feature that build lacks.

```sh
--8<-- "docs/part15/code/older_builds.sh"
```

Real output (the 22-test suite; Chapter 16 re-runs this with 34):

```text
--8<-- "docs/part15/code/older_out.txt"
```

The Chapter 7 build fails 13 and passes 9: every dynamic-shape test, the mixed-type canonicalizer test, the unranked test and every runtime-check test fail. The nine passes are the static ones plus the dynamic-extent transpose fold (Chapter 3's original pattern already handled the exact-type case), which is right: that behavior never changed. The Chapter 13 build, which has dynamic shapes but no runtime check, fails exactly the tests about the runtime check. One failure on the Chapter 7 build is *not* a missing feature: `verifier/add-static-mismatch` fails because the error **wording** changed in Chapter 13 ("operands must have the same shape" became "operands must have compatible shapes"), not because the behavior (rejecting the program) changed. Pinning diagnostic text makes a test brittle in that way. It was kept deliberately: if the message changes, a human should look.

### Check 2: three deliberate bugs in the current source

`mutation.sh` copies Chapter 14's source tree three times, introduces one bug in each copy, builds it, and runs the suite:

```sh
--8<-- "docs/part15/code/mutation.sh"
```

Real output:

```text
--8<-- "docs/part15/code/mutation_out.txt"
```

Every mutation is caught, by the tests aimed at it: the canonicalizer guard (Chapter 13's bug returning) by `transpose-twice-dynamic-mixed`; the missing dimension check by the lowering tests that expect an assert for dimension 1 and by the column-only mismatch test; the forgotten bufferization check by `bufferize-dynamic-add` and the abort tests.

**The second mutation exposed a weakness in the suite as first written**, which is the main thing this check is for. With 21 tests, "check only dimension 0" was caught *only* by tests of the IR's structure; no native test ever mismatched the columns while the rows agreed, because Chapter 13's mismatch case differs in rows first. A runtime bug that structural tests happened to anticipate would have slipped past every native test. The 22nd test, `mismatch-columns-aborts` (shown in Group 5), was added to close that, and the mutation was re-run: it now fails there too.

## What the suite does not cover

- **No CI.** Nothing runs these tests automatically on a push; they run when someone executes `./run_lit.sh`. A GitHub Actions workflow is the natural next step and is not written here, partly because it would need the MLIR 18 packages installed on the runner, which this sandbox cannot test.
- **Coverage at the end of this chapter:** Chapters 1, 2, 9, 10, 11 and 12 had no tests. *(Update, added after Chapter 16: Chapters 10 through 12 and Chapter 7's tiling and unrolling are now covered, taking the suite to 34 tests; Chapters 1, 2 and 9 are still untested.)*
- **Loop transforms: one test** at the end of this chapter (fusion only).
- **Tests encode current behavior.** They show the compiler behaves as it does now, not that it is *correct*; the expected values were taken from outputs Chapters 3 through 14 had already validated by hand.
- **The abort message** is only checked under `stdbuf -oL`, because testing it when piped would be testing the C library, not `mg`.
- **Diagnostics are pinned verbatim**, with the brittleness described above.

## Reproducing this chapter

```bash
pip install lit                        # lit 23.1.2 was used
../part14/code/build.sh                # builds the mg-opt under test
cd docs/part15/code
./run_lit.sh                           # the suite
./show.sh                              # regenerates every output shown on this page under show/
./older_builds.sh                      # the same suite against Chapter 7's and Chapter 13's builds
./mutation.sh                          # the three source mutations
```

Every test, script and output shown above is embedded from the repository when the site is built, so this page cannot drift from the code it describes (a missing file fails the build). As in Chapters 10 through 14, no documentation was consulted for any claim here; the `not --crash` behavior, the `lit` version mismatch and every result above come from running the commands.

## Chapter summary

This chapter replaced "run once and paste the output" with an assertion-based suite of 22 `lit`/`FileCheck` tests across the verifier, the canonicalizer, both lowering paths, loop fusion and native execution, every one printed on the page beside the real output it matches. A first-run failure (`lit`'s built-in `not` rejecting `--crash`) was fixed by routing `not` through LLVM's own `not-18`. Because a suite that has only passed has not been shown to test anything, the same tests were run against older builds (13 failures on Chapter 7's, 6 on Chapter 13's, each a feature that build lacks) and against three deliberate source bugs, each caught by the tests aimed at it. The mutation check exposed a real gap in the suite as first written, a check covering only dimension 0, closed by a column-only mismatch test.

Deliberately out of scope, stated explicitly: no CI runs the suite on a push, Chapters 1, 2, 9 and the GPU chapters had no tests at the end of this chapter (Chapter 16 covers the GPU path and two more loop transforms), `lit` came from PyPI at a different version from the toolchain, and diagnostics are pinned verbatim, which makes some tests brittle.

## Self-check questions

**1. What does `CHECK-NOT` assert, and which tests lean on it to show that the dynamic-shape work costs static programs nothing?**

Worked answer: `CHECK-NOT: text` requires that `text` does not appear between the surrounding matches. The static lowering tests (`static-add-affine` and `bufferize-static-add`) use `CHECK-NOT: cf.assert` and `CHECK-NOT: memref.dim` after the loop checks, so if the dynamic machinery leaked into a static program the test would fail.

**2. Why is the `mg-opt` under test chosen by an environment variable rather than hard-coded in `lit.cfg.py`?**

Worked answer: so the identical suite can be pointed at other builds. That is how the chapter shows the tests can fail: `older_builds.sh` runs the unchanged tests with `MG_OPT` set to Chapter 7's and Chapter 13's builds, and `mutation.sh` sets it to builds with deliberate bugs. A suite tied to one binary could only ever report on that binary.

**3. The two `not --crash` tests failed on the first run, while the verifier tests written with plain `not` passed. Why was that not good enough, and what was the fix?**

Worked answer: `lit`'s builtin `not` did not support `--crash` ("`not`: command not found" for that form), so those tests could not run. The plain-`not` tests passing was not reassuring either, because at that point a passing `not` test could not be told apart from a broken one. The fix was to define `%not` as LLVM's `not-18`, which supports `--crash`, and use it everywhere; the older-build runs then showed the verifier tests really do fail when the behavior is absent.

**4. What did mutating the code to check only dimension 0 reveal about the suite as first written?**

Worked answer: with 21 tests, that mutation was caught only by tests of the IR's structure (the lowering tests expecting an assert for dimension 1). No native test mismatched the columns while the rows agreed, because the only mismatch case differs in rows first, so a runtime bug in dimension 1 could have passed every executable test. The 22nd test, `mismatch-columns-aborts` (2x3 plus 2x2), was added and the mutation re-run: it now fails there too.

**5. Why is pinning an exact diagnostic message a double-edged choice? Give the example from this chapter.**

Worked answer: it makes the test strict about wording, so it also fails when only the text changes. On Chapter 7's build, `verifier/add-static-mismatch` fails not because the program is accepted but because the message then read "operands must have the same shape" and Chapter 13 changed it to "operands must have compatible shapes". The test was kept pinned deliberately, on the view that a changed message should make a human look, but it is a brittleness a reader should know about.
