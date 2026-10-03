# 25. Keeping It Working: Continuous Integration and the Tests the Early Chapters Never Had

<p style="text-align:center"><img src="../assets/goats/ch-25.svg" alt="Mountain goats on the mountain above a desert" style="max-width:100%;height:auto;border-radius:6px"></p>

**What you will understand:** what "continuous integration" is, how to build a small one for this book (a script plus a workflow file), how to check that it fails when it should, and why the honest description of a CI setup says what has actually run it and what has not. Along the way this chapter fills a gap listed since Chapter 15: Chapters 1, 2 and 9 had never had automated tests.

**What you need to know first:** Chapter 15 (the `lit` test suite and what `FileCheck` does), Chapters 21 to 24 (the suite has grown to 99 tests and the compiler to its newest build). Nothing about GitHub or CI is assumed.

!!! tip "Compile and run"
    ```sh
    cd <repository root>
    pip install -r requirements.txt           # lit, mkdocs: the Python tools (see below for the system packages)
    ./ci.sh                                   # everything CI does: tools, workflow check, build, tests, docs (about 80 s with a warm build)
    docs/part25/code/ci_failure_demo.sh       # run CI against an old compiler on purpose: it must FAIL
    docs/part25/code/chapter_tests_mutation.sh   # damage the early chapters' files on purpose: the new tests must notice
    cd docs/part15/code && ./run_lit.sh       # just the test suite (102 tests)
    ```
    The system packages are `clang-18 llvm-18-dev llvm-18-tools libmlir-18-dev mlir-18-tools cmake make`. Every listing and output on this page comes from these commands.

!!! note "Why this page shows FAIL lines, and why that is good"
    Two outputs here come from **negative controls**: CI run against a deliberately old compiler, and the new tests run against deliberately damaged example files. There a FAIL, "CI FAILED" or "caught by" is the expected, wanted result. The normal CI run and the baseline lines must pass, and they do.

## Primer: what continuous integration is

A **test suite** only protects a project if somebody runs it. **Continuous integration** (CI) means a machine runs it for you, automatically, every time the code changes: on every push to the main branch, and on every proposed change (a *pull request*) before anyone merges it. If anything fails, the change is marked red where everyone can see it, and the author hears about it within minutes instead of a reader finding it weeks later.

CI is a small idea with two parts. **The script** does the work: build the thing, run the tests, report pass or fail through its **exit status** (0 for success, anything else for failure; that number is the only thing the machinery looks at). **The workflow file** tells a service (here GitHub Actions) *when* to run the script and *on what kind of computer*: a fresh, empty virtual machine, which is the point. A fresh machine has none of your leftover files and none of the packages you installed years ago and forgot, so a successful run there proves the project builds from nothing.

For this book that matters more than usual. The tests depend on LLVM and MLIR version 18, on `cmake`, on `lit`, on a particular `FileCheck`, and on files built by earlier chapters. Every one of those is something that can be installed on the author's machine and missing, or the wrong version, everywhere else.

## The script: `ci.sh`

The script is the single source of truth. Everything CI does is in it, and you can run exactly the same thing on your own machine:

```sh
--8<-- "ci.sh"
```

Read it as five steps. It checks that the tools exist (so a missing package produces a clear message, not a mysterious failure inside a test), checks the workflow file (next section), builds the newest compiler (`docs/part24/code/build.sh`), runs the whole suite (`run_lit.sh`), and builds the documentation with `mkdocs build --strict`, which fails on any broken link or missing embedded file. Each step records pass or fail and its time; at the end the script prints a summary and exits 1 if anything failed. A failed build skips the test step instead of running tests against a compiler that does not exist.

A real run, from a warm build directory:

```text
--8<-- "docs/part25/code/ci_run_out.txt:156:162"
```

(The summary is the last few lines of the run's output; above it, in the real output, are the build log, the 102 test results and the documentation build.) On a fresh runner the compiler build takes several minutes, not the one minute shown here; the workflow caches it (below).

Knobs for local use: `CI_SKIP_BUILD=1` reuses an existing build, `CI_SKIP_DOCS=1` skips the site build, and `MG_OPT=/path/to/mg-opt` tests a different compiler build.

## The workflow file

```yaml
--8<-- ".github/workflows/ci.yml"
```

What each part does. **`on:`** says when: on every push to `main`, on every pull request, and on demand (`workflow_dispatch` adds a "Run workflow" button). **`concurrency`** cancels an older run of the same branch when a newer push arrives, so a burst of pushes does not queue up. **`runs-on: ubuntu-24.04`** is the fresh machine; Ubuntu 24.04 is the platform this book has used throughout, and it provides LLVM and MLIR 18 as packages. **The install step** gets exactly the system packages the book has needed. **`setup-python`** provides a Python without the "externally managed" restrictions of the system one, and `pip install -r requirements.txt` installs the pinned versions of `lit` and `mkdocs-material` (the same versions the book was written with). **The cache step** saves the compiler build between runs, keyed on a hash of every source file that goes into it: when none changed, the several-minute build becomes a no-op, and when any changed the key changes and a fresh build runs. Finally the one step that matters: `./ci.sh`.

`.github/check_ci.py` is the check from step 2 of the script. It parses the workflow, confirms it triggers on pushes to `main` and on pull requests, confirms the packages above are installed, and confirms that every file and path the workflow mentions exists. It catches the mistakes you can catch without GitHub (a typo in a path, a deleted script):

```python
--8<-- ".github/check_ci.py"
```

## What was established, and what was not

This section was first written **before** the workflow had ever run, because the environment this book is written in can push code but could not start or watch GitHub Actions. It said so, listed what was and was not established, and told the reader to look at the Actions tab. The push of this chapter then triggered the workflow's first real run, and it can be checked, so here is the record, in two parts.

**Before the first run, established:** `ci.sh` passes from start to finish on the author's machine (shown above); `check_ci.py` finds nothing wrong with the workflow; and `ci.sh` fails with exit status 1 when the tests fail (the demonstration below). **Not established:** that GitHub accepts the file, that the package names resolve on a fresh Ubuntu 24.04 runner, that the cached build is restored, and that the run finishes within its time limit.

**The first real run** (the `ci` workflow, run number 1, on the push that carried this chapter, commit `d8b1c2e`, read back through the GitHub API) **passed**. From its job log:

```text
=== check tools ... PASS (3 s)        === check workflow file ... PASS (0 s)
=== build the compiler ... PASS (46 s)    (from nothing: the cache was empty)
=== run the test suite ... PASS (24 s)    Total Discovered Tests: 102   Passed: 102 (100.00%)
=== build the documentation ... PASS (4 s)
CI passed.      whole job: about two minutes
```

That settles three of the four open items: **GitHub accepted the file** (a parse is not validation, but the run exists with every step listed), the **package names resolve on a fresh runner** (the install step took 25 seconds and everything after it found its tools), and the **run is far inside the 45-minute limit**. It also shows something the local run could not: the compiler builds from nothing in 46 seconds on a GitHub runner, much faster than the several minutes I had guessed above. The test suite took 24 seconds there (the Chapter 9 test, which builds a C++ program against MLIR, finished last).

**Runs 2 and 3: the cache, and a bug in my own workflow.** The push that recorded the paragraph above only touched documentation, so the compiler sources were unchanged and the cache key matched. Run 2 passed, and its log says `Cache hit occurred on the primary key mg-opt-Linux-…, not saving cache`: **the cache was restored.** But the summary also said `PASS build the compiler 35s`. A restored cache that still takes 35 seconds to "build" is a cache doing nothing. The reason is in `build.sh`: it copies the source files into a `tree/` directory on every run, so every file has a fresh modification time, newer than the restored object files, and `make` correctly decides everything is out of date and rebuilds it. (The 35 seconds against the first run's 46 is runner variance, not a saving.)

The fix is to use the information the cache step already gives: an *exact* hit on a key that is a hash of all the compiler's sources means the restored build is current. The step now has an `id`, and the `./ci.sh` step sets `CI_SKIP_BUILD=1` when `steps.cache.outputs.cache-hit` is true (the script already knew how to reuse an existing build). Run 3, on the commit that made that change, shows it working in its log:

```text
PASS check tools            1s       PASS run the test suite     24s
PASS check workflow file    1s       PASS build the documentation 4s
PASS build the compiler     0s       CI passed.      (whole job: 66 s, against 95 s for run 2)
Cache hit occurred on the primary key mg-opt-Linux-…, not saving cache.
```

So the cache restore **is** established, and so is the fix. The lesson is a general one about caching: a cache can hit and still save nothing, and the only way to know is to look at what the cached step cost afterwards. This one would have gone on looking healthy ("Cache restored") while saving nothing.

**Still not established:**

- **Stability over time.** Three runs, all passing, are evidence that the setup works, not that it will keep working: a new runner image, a changed package version or a flaky test would show up only over many runs.
- **A failing run on GitHub.** Every GitHub run so far passed. That `ci.sh` exits 1 and so would turn a run red is shown locally (below), but a red run has not been seen on GitHub itself.
- **The warning the runs print.** GitHub reports that `actions/checkout@v4`, `actions/cache@v4` and `actions/setup-python@v5` target Node.js 20, which is deprecated, and is forcing them onto Node.js 24. They work; the versions will need bumping eventually, and the workflow is not changed for that here.

## CI must be able to fail

A CI script that always says "passed" is worse than none. So, as in Chapter 15, there is a negative control: run `ci.sh` against the *old* Chapter 14 compiler, which lacks most of what the tests check.

```sh
--8<-- "docs/part25/code/ci_failure_demo.sh"
```

```text
--8<-- "docs/part25/code/ci_failure_demo_out.txt"
```

The suite fails, the summary shows `FAIL run the test suite`, and `ci.sh` exits with status 1, which is exactly what a CI service reads as "red". The step that tests the compiler build is skipped here on purpose (the old build is supplied from outside), and the documentation step is skipped to keep the demonstration short.

## The tests the early chapters never had

The suite had no test for Chapters 1, 2 or 9. Chapter 1's page even said so ("the `scf.for` demonstration here is untested beyond the single recorded run shown above"). Three tests in `test/chapters/` now run those chapters' own files:

| Test | What it runs |
|---|---|
| `ch01-pipeline` | Chapter 1's `sum.mlir`: parse and verify it, lower it with the four passes, check that the structured loop is *gone* and the single memref argument became five scalars, translate to LLVM IR, compile with the chapter's `harness.c`, run, and check the output `sum_array({1,2,3,4,5}) = 15` |
| `ch02-example-programs` | Chapter 2's three example programs with the *current* compiler: the valid one still parses and prints its operations; the transpose with the wrong shape and the add with mismatched ranks are rejected with the exact messages. (Chapter 2's own compiler accepted the mismatched add; Chapter 3 added the check, so rejecting it now is later, correct behavior.) |
| `ch09-execution-engine` | Chapter 9's C++ program, built from the chapter's own `CMakeLists.txt` in a temporary directory and run on Chapter 8's lowered IR through MLIR's JIT, checking the printed matrix `6 8 / 10 12`. This one takes the longest (about a minute on a fresh build) because it builds a C++ program against MLIR |

These tests read the chapters' files **in place** (through a `%docs` substitution), so a chapter's page, its files and its test cannot drift apart. They also mean that damage to those files now has a consequence, which `chapter_tests_mutation.sh` checks by making each file wrong, one at a time (Chapter 1's loop subtracts instead of adds; Chapter 2's valid program loses its transpose; Chapter 2's "bad" transpose is made valid; Chapter 9's lowered add subtracts):

```sh
--8<-- "docs/part25/code/chapter_tests_mutation.sh"
```

```text
--8<-- "docs/part25/code/chapter_tests_mutation_out.txt"
```

Every damage is caught by the test for that chapter, and nothing else fails. The full suite, 102 tests, with the newest compiler:

```text
--8<-- "docs/part15/code/run_out_102.txt"
```

## Limits and what is not established

- **Three real runs so far** (above), all passed; no failing run has been seen on GitHub, and stability over many runs is not yet observed.
- **The documentation step only checks that the site builds.** It does not check that the pages say true things; the tests and the "FAIL is expected" notes exist for that.
- **Only the newest compiler build is built and tested.** The older chapters' own builds (Chapters 2 to 7, 13, 14, 19, 20, 21, 22) are not rebuilt by CI; their `build.sh` scripts were run once when written. A change that broke only an old chapter's build would not be noticed.
- **The negative controls and mutation scripts are not run by CI** (they take minutes and several rebuild the compiler). They are evidence about the tests, run by hand and recorded.
- **No performance checks.** CI deliberately does not run the benchmarks (Chapters 23 and 24); timings on shared runners are too noisy to gate on.
- **No GPU or hardware-specific testing.** The GPU path is compile-only everywhere, including here.
- **One platform:** Ubuntu 24.04 with LLVM 18. Nothing here says the book builds on macOS, Windows, or other LLVM versions.

## Reproducing

```sh
pip install -r requirements.txt
./ci.sh
docs/part25/code/ci_failure_demo.sh > docs/part25/code/ci_failure_demo_out.txt
docs/part25/code/chapter_tests_mutation.sh > docs/part25/code/chapter_tests_mutation_out.txt
cd docs/part15/code && ./run_lit.sh        # 102 tests
```

## Chapter summary

- Continuous integration is a script (the work; its exit status is the verdict) plus a workflow file (when and where to run it). `ci.sh` and `.github/workflows/ci.yml` implement both for this book.
- `ci.sh` checks the tools, checks the workflow, builds the newest compiler, runs the 102-test suite and builds the docs with `--strict`; it exits 1 on any failure, and a failed build skips the tests that depend on it.
- It was shown able to fail: against an old compiler, 49 tests fail and `ci.sh` exits 1.
- Three new tests give Chapters 1, 2 and 9 automated coverage of their own files; four deliberate damages to those files are all caught.
- The chapter first said the workflow had not been run by GitHub rather than claiming CI works; its first real run then passed (102 tests, compiler built from nothing in 46 s), and a second and third run showed the cache restoring but initially saving nothing (fixed). A failing run on GitHub and long-run stability are still to be observed.

## Self-check questions

Each answer is collapsed; try the question first.

1. Why is the CI work in a script rather than written directly in the workflow file?

    ??? note "Answer"
        A script can be run on your own machine, so a failure in CI can be reproduced and fixed without pushing and waiting. The workflow file is then only about *when* and *where* (triggers, a fresh machine, installing packages), and it does not tie the project to one CI service: another service could call the same script.

2. What does "exit status" have to do with CI, and why does it matter that `ci.sh` exits 1 on failure?

    ??? note "Answer"
        A CI service does not read your test output; it looks at the exit status of the step it ran. Zero means success and anything else means failure. If `ci.sh` printed failures but still exited 0, CI would show green over failing tests. The failure demonstration exists to show it exits 1 when tests fail.

3. Why does CI run on a fresh machine, and what kind of problem does that expose?

    ??? note "Answer"
        A fresh machine has none of your leftover files, none of the packages installed long ago, and none of the environment variables you set, so it shows whether the project builds from nothing. It exposes dependencies you forgot you had: a package only installed on your machine, a file only present in your working directory, an older tool version.

4. Before the workflow's first real run, what had been established about it, and what changed afterwards?

    ??? note "Answer"
        Before: the script it calls passed locally, a parse of the workflow found no inconsistency (triggers, packages, paths), and the script failed when tests failed. Not established: that GitHub accepted the file, that the packages installed on a fresh runner, that the cache restored, and that the run finished in time. The environment could not run GitHub Actions. The first real run then passed (102 tests, compiler built from nothing in 46 s), settling acceptance, packages and time; only the cache restore and long-run stability remained open.

5. Why is the compiler build cached, and what decides when the cache is used?

    ??? note "Answer"
        Building the compiler takes several minutes on a fresh machine, so rebuilding it on every push wastes time. The cache stores the build directory under a key that is a hash of every source file that goes into the compiler; if none changed, the key matches and the build is restored, and if any changed the key differs, so a fresh build runs and a new cache is saved. A hit alone does not skip the build, though: in this repository `build.sh` recopies the sources, which makes `make` rebuild everything, so the workflow also tells `ci.sh` to skip building on an exact hit. The first version of the workflow had the cache and still took 35 seconds to build; only reading the timing in the log showed it.

6. Why does `ci.sh` skip the test step when the build step fails?

    ??? note "Answer"
        Running the tests against a compiler that was not built would produce dozens of unrelated-looking failures that hide the real cause. Skipping the dependent step keeps the failure report short and points at the first thing that broke.

7. Chapter 2's compiler accepted the mismatched add, but the new Chapter 2 test expects it to be *rejected*. Is the test wrong?

    ??? note "Answer"
        No. The test runs Chapter 2's example files with the *current* compiler, not with Chapter 2's. Chapter 3 added the shape check, so rejecting that program is the later, correct behavior, and a test expecting acceptance would assert a bug. The test says so in its comment.

8. Why are the mutation scripts and benchmarks not run by CI?

    ??? note "Answer"
        The mutation scripts take minutes and several rebuild the compiler for each injected bug; they are evidence about the quality of the tests, not checks that must pass on every push. The benchmarks measure speed, which on shared runners is too noisy to gate on: a test that fails when a neighbor is busy teaches people to ignore red. They are run by hand and their results recorded.

9. What kind of mistake would the `check_ci.py` script catch, and what kind would it miss?

    ??? note "Answer"
        It catches mistakes you can see without GitHub: invalid YAML, a missing trigger, a deleted script, a path in the cache key that does not exist, a forgotten package. It misses anything only GitHub knows: whether an action version exists, whether a package name resolves on the runner image, whether the syntax is valid by GitHub's own rules. A successful parse is not validation.

10. The chapter was written and committed before the workflow's first run, and said so. Why not wait and write it afterwards, and what would have been the right response had the run failed?

    ??? note "Answer"
        Waiting would have hidden the real order of events and tempted the text to claim more than had been known at the time; stating what was unknown, then recording what the run showed, keeps the two apart and makes the unknowns checkable. Had the run failed, the failure would have been a finding: read the log, fix the workflow or the script, note which of the "not established" items it turned out to be, and rerun. A run that passes does not close every question (cache restore and stability remain), which is why the section still lists what is open.
