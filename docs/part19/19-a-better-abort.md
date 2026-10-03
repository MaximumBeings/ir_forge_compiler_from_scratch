# 19. A Better Abort: Reporting Assertion Failures on stderr

![Mountain goats on the mountain in autumn](../assets/goats/ch-19.svg){ style="display:block;margin:0 auto;max-width:100%;height:auto;border-radius:6px" }

**What you will understand:** how to replace the lowering of MLIR's `cf.assert` with a small custom pass, so a failed runtime check reports its message on **standard error** and never loses it. Chapter 14 closed an out-of-bounds read with a runtime shape check, but found that its explanation vanished whenever stdout was a pipe or a file. This chapter fixes that, shows the fix working in three ways of capturing output, and then does what the earlier chapters' lessons demand: attacks it. Two real bugs surfaced while hardening the pass (an invalid-IR case and a symbol collision), each reproduced with its actual error text. All code, tests and outputs are embedded from the repository.

**What you need to know first:** Chapter 14's runtime check (`cf.assert`, abort on shape mismatch) and the stdout-buffering problem it found. New ground: file descriptors, the `write` system call, and writing an MLIR rewrite pattern that splits blocks.

!!! tip "Compile and run"
    Every command, listing and output on this page is reproduced by the commands in [Reproducing this chapter](#reproducing-this-chapter) at the bottom of the page, which also lists what must be built first. The chain of builds is in [Getting Started](../getting-started.md#which-build-does-each-chapter-need).


!!! note "Why this page shows FAIL lines, and why that is good"
    Parts of this page come from **negative controls**: the same tests run against an *older* build, or against *deliberately broken* code (a "mutation"). In those runs a **FAIL is the expected, wanted result**: it means a test noticed the problem, which is how we know the tests are worth anything. What would be wrong is the opposite, a deliberately broken build that passes everything. The **baseline** (the unmodified current build) must always show every test passing, and it does. Each script that does this says so in its own header and prints a reminder at the top of its output.

## Primer: why a message can vanish

A running Unix program has three standard **file descriptors**: 0 (input), 1 (standard output, "stdout") and 2 (standard error, "stderr"). A program that prints with C's `puts` writes to the stdio library's *buffered* stdout stream: the text is held in memory and only sent to descriptor 1 when the buffer fills, is flushed, or the program exits normally. When stdout is a terminal the library flushes at each newline, so you see the text immediately. When stdout is a **pipe or a file** it flushes only when the buffer fills or at exit.

`abort()` ends the process at once, by raising `SIGABRT`. It does **not** flush stdio buffers. So the sequence "print a message with `puts`, then `abort()`" loses the message whenever stdout is not a terminal, which is exactly what MLIR's own lowering of `cf.assert` does (Chapter 14 read the lowered code: `call @puts`, then `call @abort`). There are two separate flaws: the buffering, and the stream (error messages belong on stderr, not stdout).

The `write(fd, buffer, length)` function is different in kind. It is a thin wrapper over the operating system's write call: **there is no buffer to flush**. Once `write` returns, the bytes have been handed to the kernel, so a following `abort()` cannot lose them. Writing to descriptor 2 with `write` fixes both flaws at once.

## The problem, shown side by side

`demo.sh` builds the same mismatched call (a 2x3 plus a 1x2 `mg.add`, Chapter 13's `harness_mismatch.c`) two ways, Chapter 14's default lowering and this chapter's pass, and observes each under three ways of capturing output. The complete, unedited output (`demo_out.txt`):

```sh
--8<-- "docs/part19/code/demo.sh"
```

```text
--8<-- "docs/part19/code/demo_out.txt"
```

The old lowering prints **nothing** under any of the three captures shown (stdout is a pipe in the first, a file in the second, and the stderr-only view in the third finds nothing because the message was on stdout and never flushed). The new pass puts the message on stderr in two of the three; in the middle case stderr was deliberately discarded, so an empty stdout file is the correct result. Both builds still die with exit status 134 (`SIGABRT`): the safety property never changed, only whether the explanation survives.

## Design

What the pass must do for each `cf.assert %cond, "message"`: if `%cond` is true, continue; if false, write the message to descriptor 2, then abort. In MLIR terms that is a conditional branch and a new block:

```text
    cf.cond_br %cond, ^continue, ^fail
  ^fail:
    llvm.call @write(2, <message>, <length>)
    llvm.call @abort()
    llvm.unreachable
```

The message becomes a private constant string global in the module, and `llvm.mlir.addressof` takes its address. The pass uses the `llvm` dialect's operations directly inside the `func.func` body; the book's usual lowering passes later convert everything else around them, and `llvm.call` operations are left alone.

Two alternatives were considered and **not built**: calling `fflush(NULL)` between the `puts` and the `abort`, which would fix the buffering but leave the message on stdout; and calling `fputs` on the C library's `stderr` object, which needs a platform-specific global symbol (the name differs between systems). The `write(2, ...)` route needs no `FILE*` and no platform-specific symbol beyond `write` and `abort` themselves.

## The implementation

The whole pass, `AssertToStderr.cpp`, in sections. The header comment and includes:

```cpp
--8<-- "docs/part19/code/AssertToStderr.cpp:1:16"
```

A helper that declares `write` and `abort` once, at module level, as external `llvm.func`s:

```cpp
--8<-- "docs/part19/code/AssertToStderr.cpp:19:25"
```

The rewrite pattern. It begins with a guard (explained below), then makes the message global, then rewrites the control flow:

```cpp
--8<-- "docs/part19/code/AssertToStderr.cpp:27:80"
```

Reading the middle of it: `rewriter.splitBlock(here, Block::iterator(op))` cuts the block at the assert, leaving everything *after* the assert in a new block `cont`; `rewriter.createBlock(cont)` creates the failing block `fail` just before it; the failing block gets the constants, the `addressof`, the two calls and `llvm.unreachable`; and the original block now ends with a `cf.cond_br` on the assert's condition. Finally the assert itself is erased. The global's name is chosen by searching for the first `mg_assert_stderr_msg_<k>` not already defined in the module (a fix described below), and the message gets a trailing newline appended before it is stored.

The pass wrapper and its registration, which follow the exact pattern Chapter 4's pass used:

```cpp
--8<-- "docs/part19/code/AssertToStderr.cpp:82:102"
```

Wiring it into `mg-opt` and the build is a small change, shown here in full (`chapter19.diff`: 38 lines against Chapter 14's `mg-opt.cpp` and `CMakeLists.txt`):

```diff
--8<-- "docs/part19/code/chapter19.diff"
```

`build.sh` assembles the compiler from the earlier chapters' files plus this chapter's three:

```sh
--8<-- "docs/part19/code/build.sh"
```

## What the pass produces

On the dynamic add, after `--convert-mg-to-affine --mg-lower-assert-to-stderr` (`show/dyn_after_pass.mlir`, first 30 lines). The two message globals and the two declarations come first, then the function: each assert is now a `cf.cond_br` whose failing block writes and aborts, and the original computation continues in the last block:

```mlir
--8<-- "docs/part19/code/show/dyn_after_pass.mlir:1:30"
```

(The `_1`/`_0` numbering is the order the rewrite driver visited the asserts, which is the reverse of source order; it is cosmetic.) No `cf.assert` remains. The message is exactly what was asked for, byte for byte: a test message containing a double quote, a percent sign and non-ASCII text (`bad "quote" 100% done, naïve café`) arrives as these bytes on descriptor 2, with the UTF-8 sequences intact (`303 257` is `ï`, `303 251` is `é`) and exactly one trailing newline:

```text
--8<-- "docs/part19/code/show/boom_bytes.txt"
```

## Where the pass must sit in the pipeline

**The pass has to run before MLIR's own lowering sees the asserts**, because `--convert-func-to-llvm` consumes `cf.assert` itself (Chapter 14 found that lowering already handles it). Checked directly by putting the standard lowering first (`show/ordering_wrong.txt`):

```text
--8<-- "docs/part19/code/show/ordering_wrong.txt"
```

The standard lowering took both asserts (two `puts` calls) and the pass then found nothing to rewrite (zero `write` calls), with no warning. A user who adds the pass at the wrong point gets the old behavior silently. The tests below always put it before the conversion passes; the test suite's `%lower-with-stderr` substitution is the one correct ordering used in this book.

## Two bugs found while hardening it

The first version worked on the demo and passed its first tests. Attacking it with unusual inputs found two real problems, each fixed and each now pinned by a test. The sources of the broken versions are the mutation builds in the failure-injection section below, so the error text here is reproduced from those builds, not remembered.

### 1. An assert inside a loop made invalid IR

An `affine.for` body is a region that must have exactly one block. The first version of the pattern split blocks wherever it found a `cf.assert`, so an assert inside a loop body produced IR with several blocks in a single-block region. The input (`nested.mlir`, a loop that asserts every element is not NaN):

```mlir
--8<-- "docs/part15/code/test/Inputs/nested.mlir"
```

and the error the unguarded pass produced on it (`bugs/nested_without_guard.txt`):

```text
--8<-- "docs/part19/code/bugs/nested_without_guard.txt"
```

The fix is the guard at the top of the pattern: **only rewrite an assert whose parent is a `func.func`**, where multiple blocks are legal. Others are left for MLIR's default lowering. Placing the pass *after* `--lower-affine --convert-scf-to-cf`, when no structured loops remain, makes every assert eligible; both placements are tested, and the nested program was run for real (clean data survives, a NaN at index 3 aborts with `value is NaN` on stderr).

### 2. Running the pass twice collided on global names

The first version numbered its message globals from a counter that restarted at zero on each run. A module with a top-level assert and a nested one, run through the pass, then flattened, then through the pass again, rewrote the top-level assert on the first run (global `_0`) and the nested one on the second, reusing the name `_0` (`bugs/twice_without_unique_names.txt`):

```text
--8<-- "docs/part19/code/bugs/twice_without_unique_names.txt"
```

The fix is in the code shown above: search the module for the first unused name instead of counting. The input and the final names (`twice_out.mlir`):

```mlir
--8<-- "docs/part15/code/test/Inputs/twice.mlir"
```

```text
--8<-- "docs/part19/code/show/twice_globals.txt"
```

## The tests

Eight new tests, in `test/assert-stderr/`, bring the suite to 52 (`run_out_52.txt` below). They are shown in full; each header says what it pins down. The shape of the rewrite:

```mlir
--8<-- "docs/part15/code/test/assert-stderr/rewrite-structure.mlir"
```

That a program with no assertions passes through unchanged:

```mlir
--8<-- "docs/part15/code/test/assert-stderr/static-unchanged.mlir"
```

The reason the pass exists: the message reaches stderr, on both lowering paths, with stdout discarded:

```mlir
--8<-- "docs/part15/code/test/assert-stderr/message-on-stderr.mlir"
```

That valid programs are unaffected (eleven runtime shapes):

```mlir
--8<-- "docs/part15/code/test/assert-stderr/valid-shapes-still-pass.mlir"
```

The guard, in both placements:

```mlir
--8<-- "docs/part15/code/test/assert-stderr/guard-nested-assert.mlir"
```

The nested assert run for real, with the message on stderr:

```mlir
--8<-- "docs/part15/code/test/assert-stderr/nested-assert-runs.mlir"
```

The exact bytes, with `--match-full-lines` so nothing else may share the line:

```mlir
--8<-- "docs/part15/code/test/assert-stderr/message-bytes-exact.mlir"
```

And the collision fix:

```mlir
--8<-- "docs/part15/code/test/assert-stderr/run-twice-no-collision.mlir"
```

The suite, all 52 passing on this chapter's build (`run_out_52.txt`):

```text
--8<-- "docs/part15/code/run_out_52.txt"
```

### Can the tests fail?

**Against Chapter 14's build**, which has no such pass, the same 52 tests give (`older_build_out.txt`):

```text
--8<-- "docs/part19/code/older_build_out.txt"
```

All eight new tests fail and the 44 older ones pass. This is weaker evidence than it looks for some of them (`static-unchanged` fails there only because the option `--mg-lower-assert-to-stderr` does not exist), so a second, stronger check follows.

**Seven deliberate bugs in the pass's own source**, each applied to a copy of this chapter's source tree, rebuilt, and tested. The script:

```sh
--8<-- "docs/part19/code/stderr_mutation.sh"
```

and its complete, unedited output:

```text
--8<-- "docs/part19/code/stderr_mutation_out.txt"
```

Reading it: writing to descriptor 1 instead of 2 (mutation 1) fails exactly the tests that discard stdout; dropping the abort (2) fails the tests that require a crash and the structure test; removing the guard (3) fails the guard test and the run-twice test (whose first pass run also meets the nested assert); truncating the length (4) fails the exact-bytes test and the two that match the message; swapping the branch targets so *valid* programs abort (5) fails `valid-shapes-still-pass`; declaring `abort` even when there is nothing to rewrite (6) fails `static-unchanged`; and removing the unique-name search (7) fails four tests, not just the collision test: with the search gone, even a single run over a program with two asserts (the shape-mismatch programs) gives both globals the same name. Mutations 5 and 6 were added after the first four, because two tests (`valid-shapes-still-pass` and `static-unchanged`) had not failed under any mutation, which meant they had not yet been shown able to fail. Mutation 7 was added after the collision bug was found. Every one of the eight new tests has now failed under at least one mutation.

## Limits, and what this does not establish

- **POSIX only.** The pass emits calls to `write` and `abort`, both standard C-library functions on Linux (tested here) and other POSIX systems. Windows was not tried.
- **Descriptor 2 is assumed open and usable.** If it is closed, `write` fails; the return value is ignored and the program aborts anyway. Short writes and `EINTR` are not handled (a message of a few dozen bytes is written in one call in practice, but that is not guaranteed).
- **The message is a fixed string.** `cf.assert` carries a static message, so the output cannot include the actual mismatching sizes. "operand shapes differ at runtime in dimension 0" says which dimension, not what the two sizes were.
- **Only asserts directly in a function body are rewritten.** Nested ones are left to MLIR's default lowering (stdout, and lost when piped) unless the pass is placed after `--convert-scf-to-cf`.
- **Ordering matters and fails silently.** Placed after the standard lowering, the pass does nothing and says nothing (shown above).
- **The earlier chapters keep the old lowering.** Chapters 4 through 18's scripts and tests still use MLIR's default `cf.assert` lowering; only the eight new tests use this pass. The older tests that check the message do so with `stdbuf -oL` because of the buffering this chapter works around.
- **Still SIGABRT.** The response to a mismatch is process death with exit status 134, not a recoverable error.
- **No performance claims.** Nothing was timed; the pass adds no work on the success path beyond the branch the default lowering already had.

## Reproducing this chapter

```bash
cd docs/part19/code
./build.sh               # earlier chapters' files + this chapter's three -> ./build/mg-opt
./demo.sh                # the side-by-side comparison -> demo_out.txt
./show.sh                # the IR and byte evidence under show/
cd ../part15/code
./run_lit.sh             # the 52-test suite (defaults to this chapter's build)
cd ../../part19/code
./stderr_mutation.sh     # the seven mutations (rebuilds per mutation; several minutes)
```

The `bugs/` files come from the mutation builds (`work/sm-3` and `work/sm-7`) after `stderr_mutation.sh` has run; `reproduce_bugs.sh` regenerates them. Every file and output above is embedded from the repository when the site is built. As in Chapters 10 through 18, no documentation was consulted: each claim comes from running the commands or reading the code.

## Chapter summary

This chapter replaced MLIR's `cf.assert` lowering with a small pass, `--mg-lower-assert-to-stderr`, that turns each assert into a conditional branch whose failing side `write`s the message to file descriptor 2 and aborts. Chapter 14's lowering printed to buffered stdout and then aborted, so the explanation was lost whenever stdout was not a terminal; the new pass delivers it under every capture mode tried, because `write` has no buffer to flush and stderr is the right stream. Hardening it found two real bugs (an assert nested in a single-block loop body produced invalid IR, and running the pass twice reused global names), both now fixed and pinned. Eight new `lit` tests (suite: 52) and seven mutations, all caught, with two mutations added specifically because two tests had not yet been shown able to fail.

Deliberately out of scope, stated explicitly: POSIX only, descriptor 2 assumed open, short writes not handled, a fixed message string, nested asserts handled only when the pass runs after `--convert-scf-to-cf`, silent no-op if misordered, and the earlier chapters left on the default lowering.

## Self-check questions

**1. Why does `puts` followed by `abort()` lose the message when stdout is a pipe, while `write(2, ...)` followed by `abort()` does not?**

Worked answer: `puts` writes into the C library's buffered stdout stream. When stdout is a terminal the library flushes at each newline, but when it is a pipe or a file the text stays in memory until the buffer fills or the program exits normally. `abort()` ends the process immediately without flushing stdio buffers, so the text is discarded. `write` is a thin wrapper over the operating system's write call with no library buffer: when it returns the bytes are already in the kernel, so a later `abort()` cannot lose them. Writing to descriptor 2 also puts the message on the stream conventionally used for errors.

**2. The pass only rewrites an assert whose parent operation is a `func.func`. What goes wrong without that guard, and how can the pass still cover a nested assert?**

Worked answer: rewriting splits the assert's block in two and adds a failing block, which needs a region that may hold several blocks. An `affine.for` body is a single-block region, so splitting it produced invalid IR (`'affine.for' op expects region #0 to have 0 or 1 blocks`). The guard leaves such asserts to MLIR's default lowering. Running the pass after `--lower-affine --convert-scf-to-cf`, when no structured loops remain and every assert sits in a function body of blocks, makes the nested assert eligible; the nested program was then run for real and a NaN aborted with its message on stderr.

**3. Why must the pass run before `--convert-func-to-llvm`, and how would you notice if it did not?**

Worked answer: `--convert-func-to-llvm` already lowers `cf.assert` (to `puts` plus `abort`), so by the time a later pass runs, no `cf.assert` is left to rewrite and the pass silently does nothing. You would notice by looking at the IR or the behavior: with the standard lowering first, the output contains two `puts` calls and zero `write` calls, and the message is lost again when stdout is a pipe. Nothing warns about this, which is why the chapter shows it and why every test uses the one correct ordering.

**4. Running the pass twice on one module used to fail with a redefinition error. What caused it, and what was the fix?**

Worked answer: the message globals were named from a counter that restarted at zero on each run. A first run rewrote a top-level assert (global `_0`) and left a nested one; after flattening, a second run rewrote the nested one and reused `_0`, so the module had two globals with the same symbol name. The fix searches the module's symbols for the first unused `mg_assert_stderr_msg_<k>` instead of counting, so each message gets a distinct name regardless of how many times the pass runs.

**5. Two of the new tests did not fail under the first four mutations. Why did the chapter add more mutations, and which ones?**

Worked answer: a test that has never failed has not been shown to test anything. `valid-shapes-still-pass` guards against the pass breaking programs whose assertions hold, and `static-unchanged` guards against the pass altering programs it should leave alone; the first four mutations (wrong descriptor, no abort, no guard, truncated length) broke neither property. Mutation 5 swaps the branch targets so a true condition goes to the failing side, which makes valid programs abort and fails `valid-shapes-still-pass`; mutation 6 declares `abort` even when nothing needs rewriting, which changes a program with no asserts and fails `static-unchanged`. Mutation 7, removing the unique-name search, was added once the collision bug was found.
