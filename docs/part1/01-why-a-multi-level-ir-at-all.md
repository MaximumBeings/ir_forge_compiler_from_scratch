# 1. Why a Multi-Level IR at All

![Mountain goats on the mountain in autumn](../assets/goats/ch-01.svg){ style="display:block;margin:0 auto;max-width:100%;height:auto;border-radius:6px" }

**What you will understand:** why MLIR represents a program at more than one level of abstraction at once, demonstrated concretely -- one small, real, structured loop is parsed, genuinely lowered through MLIR's own real passes, translated to real LLVM IR, compiled, and run, with the exact moment its own loop structure disappears captured directly in the tool's own output.

**What you need to know first:** nothing beyond Getting Started's own stated prerequisites -- what an intermediate representation, a basic block, and SSA form are. Every MLIR-specific idea this chapter uses is introduced here, for the first time, grounded in a real example rather than a diagram.

!!! tip "Compile and run"
    ```sh
    cd docs/part1/code
    ./run.sh          # parse + verify, lower, translate, compile, link, run  (intermediates in ./work/)
    ```
    No build step: this chapter needs only `clang-18`, `mlir-opt-18` and `mlir-translate-18`. Every listing and output on this page comes from these commands (and the chapter's own embedded files).


## The real question this chapter answers

A compiler has to go from "a program a human wrote" to "machine code a CPU executes." LLVM already has a single, well-designed intermediate representation (LLVM IR) that does exactly that translation for a huge range of real source languages -- Clang lowers C/C++ straight to it, Rust lowers straight to it, dozens of other real frontends do the same. So why would MLIR -- a *second*, different IR, sitting *above* LLVM IR -- ever be worth building at all? This chapter answers that question the same way every chapter in this book answers a real question: not with a diagram, but by building one small real program two different ways and watching, in real, captured tool output, exactly what is lost when the second way skips the first.

## A small, real example: summing an array

Here is a real, complete MLIR function -- parseable, verifiable, and (by the end of this chapter) genuinely compilable and runnable -- that sums the five elements of an `i32` array:

```mlir
func.func @sum_array(%arr: memref<5xi32>) -> i32 {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c5 = arith.constant 5 : index
  %zero = arith.constant 0 : i32
  %result = scf.for %i = %c0 to %c5 step %c1 iter_args(%sum = %zero) -> (i32) {
    %val = memref.load %arr[%i] : memref<5xi32>
    %new_sum = arith.addi %sum, %val : i32
    scf.yield %new_sum : i32
  }
  return %result : i32
}
```

Three real MLIR ideas are already visible in this one small function, each one a genuine part of MLIR's own design, not this book's own invention:

- **`memref<5xi32>`** is MLIR's own real built-in type for a reference to a region of memory holding a statically-shaped, 5-element array of 32-bit integers -- distinct from a bare pointer (Appendix-level C territory this book does not need) in that the *shape* (`5`) is carried directly in the type itself, available to any real pass that wants to reason about it without having to track it separately.
- **`scf.for`** is a real operation from MLIR's own `scf` ("structured control flow") dialect -- a genuine `for`-loop construct, with a real loop-carried value (`iter_args(%sum = %zero) -> (i32)`, the running sum, threaded through each real iteration and `scf.yield`-ed back out) rather than the index-variable-plus-mutable-memory-cell shape a lower-level IR would need instead.
- **`arith.constant` / `arith.addi`** are real operations from MLIR's own `arith` dialect -- ordinary integer arithmetic, deliberately factored into its own real dialect separate from `scf`'s own control flow and `memref`'s own memory operations, so that a real pass interested in arithmetic alone never has to also understand loops or memory layout.

Confirming this is genuinely valid, parseable MLIR -- not merely plausible-looking text -- is `mlir-opt-18`'s own real job: given valid input, it parses, verifies, and prints the IR back out; given invalid input, it refuses and reports exactly what failed to verify, printing nothing.

```
mlir-opt-18 sum.mlir
```

**Real captured output (cloud sandbox, `mlir-opt-18`, Ubuntu LLVM 18.1.3):**
```text
module {
  func.func @sum_array(%arg0: memref<5xi32>) -> i32 {
    %c0 = arith.constant 0 : index
    %c1 = arith.constant 1 : index
    %c5 = arith.constant 5 : index
    %c0_i32 = arith.constant 0 : i32
    %0 = scf.for %arg1 = %c0 to %c5 step %c1 iter_args(%arg2 = %c0_i32) -> (i32) {
      %1 = memref.load %arg0[%arg1] : memref<5xi32>
      %2 = arith.addi %arg2, %1 : i32
      scf.yield %2 : i32
    }
    return %0 : i32
  }
}
```

This is genuinely the same function, re-printed by `mlir-opt-18` itself after a real round trip through its own parser and verifier (MLIR's own printer renames `%arr` to `%arg0` and wraps the function in an explicit `module { ... }` -- its own real, canonical surface form, not a change in meaning) -- confirmed valid, structurally, before this chapter does anything else with it.

## MLIR's own real, official reasoning

MLIR's own official rationale document states its own real motivation plainly. This document is unreachable at its own rendered URL (`mlir.llvm.org`) from this book's own sandbox, so this chapter instead cloned the real `llvm/llvm-project` repository itself -- the actual primary source the rendered site is itself generated from -- and read `mlir/docs/Rationale/Rationale.md` directly:

> "MLIR is a multi-level IR, i.e., it represents code at a domain-specific representation such as HLO or TensorFlow graphs, all the way down to the machine level." (`mlir/docs/Rationale/Rationale.md`, line 45)

> "MLIR's design allows a progressive lowering to target-specific forms." (same file, line 79)

And, naming exactly the kind of transformation this real multi-level design exists to make tractable:

> "Loop transformations that can be easily implemented include the body of affine transformations: these subsume all traditional loop transformations (unimodular and non-unimodular) such as loop tiling, interchange, permutation, skewing, scaling, relative shifting, reversal, fusion, and distribution/fission." (same file, line 73)

The real claim worth testing, not just quoting: a transformation like loop fusion or tiling needs the compiler to still be able to *see* a loop as a loop -- its own bounds, its own step, its own body as one recognizable unit -- to reorganize it at all. This chapter's own next step shows, directly, what happens to that recognizability once this exact same function is lowered to the level LLVM IR itself operates at.

## Watching the loop disappear

`mlir-opt-18` is also MLIR's own real pass driver: each `--pass-name` flag runs one real, named transformation over the IR, in the order given. Lowering `sum.mlir` all the way down to MLIR's own `llvm` dialect -- the dialect that mirrors real LLVM IR concepts directly, one step before leaving MLIR's own representation entirely -- takes four real, named passes, confirmed directly against this exact installed toolchain's own `mlir-opt-18 --help`:

```
mlir-opt-18 sum.mlir \
  --convert-scf-to-cf \
  --convert-arith-to-llvm \
  --finalize-memref-to-llvm \
  --convert-func-to-llvm \
  --reconcile-unrealized-casts \
  -o sum_llvm.mlir
```

**Real captured output (`sum_llvm.mlir`, written by `mlir-opt-18` itself):**
```text
module {
  llvm.func @sum_array(%arg0: !llvm.ptr, %arg1: !llvm.ptr, %arg2: i64, %arg3: i64, %arg4: i64) -> i32 {
    %0 = llvm.mlir.undef : !llvm.struct<(ptr, ptr, i64, array<1 x i64>, array<1 x i64>)>
    %1 = llvm.insertvalue %arg0, %0[0] : !llvm.struct<(ptr, ptr, i64, array<1 x i64>, array<1 x i64>)> 
    %2 = llvm.insertvalue %arg1, %1[1] : !llvm.struct<(ptr, ptr, i64, array<1 x i64>, array<1 x i64>)> 
    %3 = llvm.insertvalue %arg2, %2[2] : !llvm.struct<(ptr, ptr, i64, array<1 x i64>, array<1 x i64>)> 
    %4 = llvm.insertvalue %arg3, %3[3, 0] : !llvm.struct<(ptr, ptr, i64, array<1 x i64>, array<1 x i64>)> 
    %5 = llvm.insertvalue %arg4, %4[4, 0] : !llvm.struct<(ptr, ptr, i64, array<1 x i64>, array<1 x i64>)> 
    %6 = llvm.mlir.constant(0 : index) : i64
    %7 = llvm.mlir.constant(1 : index) : i64
    %8 = llvm.mlir.constant(5 : index) : i64
    %9 = llvm.mlir.constant(0 : i32) : i32
    llvm.br ^bb1(%6, %9 : i64, i32)
  ^bb1(%10: i64, %11: i32):  // 2 preds: ^bb0, ^bb2
    %12 = llvm.icmp "slt" %10, %8 : i64
    llvm.cond_br %12, ^bb2, ^bb3
  ^bb2:  // pred: ^bb1
    %13 = llvm.extractvalue %5[1] : !llvm.struct<(ptr, ptr, i64, array<1 x i64>, array<1 x i64>)> 
    %14 = llvm.getelementptr %13[%10] : (!llvm.ptr, i64) -> !llvm.ptr, i32
    %15 = llvm.load %14 : !llvm.ptr -> i32
    %16 = llvm.add %11, %15  : i32
    %17 = llvm.add %10, %7  : i64
    llvm.br ^bb1(%17, %16 : i64, i32)
  ^bb3:  // pred: ^bb1
    llvm.return %11 : i32
  }
}
```

Two real, concrete things happened, both worth naming directly against the real output above:

**First**, the single `memref<5xi32>` argument became *five* separate real arguments (`!llvm.ptr, !llvm.ptr, i64, i64, i64`) -- `--finalize-memref-to-llvm`'s own real job is "unpacking" MLIR's own higher-level memref type into the real, lower-level pieces LLVM IR actually has: an allocated pointer, an aligned pointer (the same value here, since this chapter's own memref was never offset or reshaped), an offset, and one (size, stride) pair per dimension -- assembled, inside the function body, into an explicit `!llvm.struct<...>` via a real sequence of `llvm.insertvalue` operations. This is a real, visible example of MLIR's own multi-level design doing real work: the `memref` type let `sum.mlir` express "a 5-element array" as one clean concept; only once a pass genuinely needs the lower-level representation does that concept get unpacked into the pieces a flatter IR would have forced the programmer to track by hand from the very first line.

**Second**, and this chapter's own real, central point: `scf.for` is **gone**. In its place are three real, ordinary basic blocks (`^bb1`, `^bb2`, `^bb3`), joined by real, explicit `llvm.br`/`llvm.cond_br` branches -- a real control-flow graph, indistinguishable, at this level, from one a programmer might have written directly with `goto` statements. `--convert-scf-to-cf`'s own real, literal job (confirmed in its own `--help` description: "replacing structured control flow with a CFG") is exactly this: the loop's own real, named identity -- "this is a `for`-loop, iterating 5 times, over this exact index range" -- has been *compiled away* into something structurally equivalent, but which no longer has a name. Nothing in `^bb1`/`^bb2`/`^bb3` alone says "this is a loop"; a transformation that wanted to fuse this loop with a neighboring one, or tile it, would first have to pattern-match the CFG shape back into "oh, this is a loop" before doing anything useful -- real, extra work the `scf`-level representation never required in the first place, confirming the real rationale quoted above directly, in this chapter's own captured output rather than only in the project's own prose.

## Finishing the real pipeline: LLVM IR, compiled, and run

MLIR's own `llvm` dialect is one more real step removed from actual LLVM IR text -- close enough to translate mechanically, via `mlir-translate-18`, MLIR's own real tool for exactly this:

```
mlir-translate-18 --mlir-to-llvmir sum_llvm.mlir -o sum.ll
```

**Real captured output (`sum.ll`, genuine LLVM IR text):**
```text
; ModuleID = 'LLVMDialectModule'
source_filename = "LLVMDialectModule"

define i32 @sum_array(ptr %0, ptr %1, i64 %2, i64 %3, i64 %4) {
  %6 = insertvalue { ptr, ptr, i64, [1 x i64], [1 x i64] } undef, ptr %0, 0
  %7 = insertvalue { ptr, ptr, i64, [1 x i64], [1 x i64] } %6, ptr %1, 1
  %8 = insertvalue { ptr, ptr, i64, [1 x i64], [1 x i64] } %7, i64 %2, 2
  %9 = insertvalue { ptr, ptr, i64, [1 x i64], [1 x i64] } %8, i64 %3, 3, 0
  %10 = insertvalue { ptr, ptr, i64, [1 x i64], [1 x i64] } %9, i64 %4, 4, 0
  br label %11

11:                                               ; preds = %15, %5
  %12 = phi i64 [ %20, %15 ], [ 0, %5 ]
  %13 = phi i32 [ %19, %15 ], [ 0, %5 ]
  %14 = icmp slt i64 %12, 5
  br i1 %14, label %15, label %21

15:                                               ; preds = %11
  %16 = extractvalue { ptr, ptr, i64, [1 x i64], [1 x i64] } %10, 1
  %17 = getelementptr i32, ptr %16, i64 %12
  %18 = load i32, ptr %17, align 4
  %19 = add i32 %13, %18
  %20 = add i64 %12, 1
  br label %11

21:                                               ; preds = %11
  ret i32 %13
}

!llvm.module.flags = !{!0}

!0 = !{i32 2, !"Debug Info Version", i32 3}
```

This is real, ordinary LLVM IR -- the exact same real representation Clang itself would produce for an equivalent hand-written C loop -- with the same real basic-block structure `sum_llvm.mlir` already showed, now in LLVM's own native textual syntax rather than MLIR's.

To prove this is genuinely correct, not merely well-formed, this chapter compiles it with Clang and calls it from a small real C program, matching the exact real five-argument "unpacked memref" calling convention `--finalize-memref-to-llvm` produced above:

```c
#include <stdio.h>
#include <stdint.h>

/* The real five-argument ABI mlir-opt-18's own --finalize-memref-to-llvm
 * pass "unpacked" the single memref<5xi32> argument into: allocated
 * pointer, aligned pointer, offset, and one (size, stride) pair per
 * dimension -- confirmed directly in sum_llvm.mlir's own real output. */
extern int32_t sum_array(int32_t *allocated, int32_t *aligned, int64_t offset,
                          int64_t size0, int64_t stride0);

int main(void) {
    int32_t data[5] = {1, 2, 3, 4, 5};
    int32_t result = sum_array(data, data, 0, 5, 1);
    printf("sum_array({1,2,3,4,5}) = %d\n", result);
    return 0;
}
```

```
clang-18 -c sum.ll -o sum.o
clang-18 -Wall -Wextra -c harness.c -o harness.o
clang-18 sum.o harness.o -o sum_demo
./sum_demo
```

**Real captured compiler output:**
```text
warning: overriding the module target triple with x86_64-pc-linux-gnu [-Woverride-module]
1 warning generated.
```

(`mlir-translate-18` writes no target-triple metadata into the LLVM IR it emits -- this chapter's own genuine, harmless Clang warning, stated honestly rather than edited out, is Clang filling that gap in with this exact real host's own triple.)

**Real captured program output:**
```text
sum_array({1,2,3,4,5}) = 15
```

`1 + 2 + 3 + 4 + 5 = 15` -- the real, correct answer, produced by a real binary that started life as a structured `scf.for` loop, was genuinely unpacked and lowered by real MLIR passes, translated to real LLVM IR, and compiled by the real LLVM backend. Every stage of that real pipeline is now proven, not asserted: this chapter's own next parts (Part 1 onward) can build a real, custom dialect on top of this exact same real lowering-and-execution discipline with confidence that the discipline itself genuinely works.

## The complete source files

The excerpts above show the parts under discussion. These files appear in `code/` and are not shown elsewhere on this page; each is embedded exactly as it exists in the repository, collapsed so the narrative stays readable.

??? note "`compile_warn.txt`"

    ```text
    --8<-- "docs/part1/code/compile_warn.txt"
    ```

??? note "`lower_out.txt`"

    ```text
    --8<-- "docs/part1/code/lower_out.txt"
    ```

??? note "`run_out.txt`"

    ```text
    --8<-- "docs/part1/code/run_out.txt"
    ```

??? note "`translate_out.txt`"

    ```text
    --8<-- "docs/part1/code/translate_out.txt"
    ```

??? note "`verify_out.txt`"

    ```text
    --8<-- "docs/part1/code/verify_out.txt"
    ```

## What later chapters changed

No later chapter changed this chapter's code. The `lit`/`FileCheck` suite built in Chapters 15 and 16 does not cover it: the `scf.for` demonstration here is untested beyond the single recorded run shown above.

## Chapter summary

This chapter answered "why a second IR above LLVM IR" concretely rather than abstractly: a real, structured `scf.for` loop was parsed and verified by `mlir-opt-18`, genuinely lowered through four real MLIR passes to MLIR's own `llvm` dialect, where its own loop structure visibly disappeared into three bare basic blocks joined by branches -- exactly the real transformation MLIR's own official rationale names as the reason loop-level transformations (fusion, tiling, interchange) belong at a *structured* level, before that information is lost. The same IR was then translated to real LLVM IR, compiled, and run, producing the correct real answer and confirming the whole real pipeline -- parse, lower, translate, compile, execute -- genuinely works end to end on this book's own confirmed toolchain.

Deliberately out of scope, stated explicitly: this chapter uses only MLIR's own pre-existing, built-in dialects (`func`, `arith`, `scf`, `memref`, `llvm`) -- no custom dialect has been defined yet; that is Part 1's own real subject. No `affine` dialect transformation (tiling, fusion) has actually been performed yet either -- this chapter only demonstrates *why* one would want to, by showing what is lost once the opportunity to do so has passed.

## Self-check questions

**1. Why does `--finalize-memref-to-llvm` turn one `memref<5xi32>` argument into five separate LLVM-level arguments, rather than one pointer?**

Worked answer: a real `memref` carries more information than a bare pointer -- not just where the data starts, but its own allocated-versus-aligned base address (these can differ in real, more general cases this chapter's own simple example doesn't exercise), and its own shape and stride in each dimension. LLVM IR has no type that bundles all of that together, so lowering to it has to make each real piece an explicit, separate value; `sum_llvm.mlir`'s own real output shows exactly that unpacking, five arguments where the source had one.

**2. The chapter claims `scf.for`'s own structure is "gone" after lowering. In what real, precise sense is that true, given that the lowered code still only sums five elements, correctly?**

Worked answer: the lowered code's own *behavior* is unchanged -- it still computes the same real sum, which the real captured program output confirms. What is gone is the explicit, nameable *fact* that this behavior came from a loop at all: `^bb1`/`^bb2`/`^bb3` with `llvm.br`/`llvm.cond_br` is a real, ordinary control-flow graph that could equally have come from a hand-written `goto` chain, a `while` loop, or several other real source constructs. A pass operating at this level has no direct way to ask "is this a loop," only "is this graph shape consistent with one" -- real, extra analysis `scf.for`'s own explicit representation never required.

**3. Why does this chapter cite `mlir/docs/Rationale/Rationale.md` read directly from a cloned `llvm/llvm-project` repository, rather than from `mlir.llvm.org`'s own rendered documentation site?**

Worked answer: `mlir.llvm.org` is unreachable from this book's own sandbox (confirmed directly, not assumed). The rendered website is itself generated from the exact same real Markdown files living in the `mlir/docs/` directory of the `llvm/llvm-project` repository -- cloning that repository and reading the file directly reaches the identical real, official text, from the actual primary source, rather than a secondary rendering of it; nothing about the citation's own strength is lost by reading the source file instead of its rendered form.

**4. Why does `harness.c`'s own `sum_array` declaration need to match the real lowered function's own five-argument shape exactly, rather than just declaring `int32_t sum_array(int32_t *arr, int len)` and hoping it links?**

Worked answer: once `sum.ll` is compiled, the real, binary calling convention is fixed by what `--finalize-memref-to-llvm` actually generated -- five real arguments in a specific real order (allocated pointer, aligned pointer, offset, size, stride) -- and the C compiler has no way to know this function started life as a one-argument MLIR function; it only sees the real LLVM IR signature `sum.ll` actually declares. A mismatched C declaration would either fail to link against the real symbol's own type, or -- worse, if argument counts and types happened to coincidentally fit into the same real registers -- silently read wrong values with no compiler error at all.

**5. The three real `arith`/`scf`/`memref` dialects used in `sum.mlir` are each separate, rather than one combined "basic operations" dialect. What real benefit does that separation buy, based on what this chapter actually demonstrated?**

Worked answer: separating dialects by concern is exactly what let this chapter's own four real lowering passes each do one focused, independently-understandable job: `--convert-scf-to-cf` only ever had to know about *control flow*, `--convert-arith-to-llvm` only ever had to know about *arithmetic*, and `--finalize-memref-to-llvm` only ever had to know about *memory layout* -- each pass genuinely ignorant of the other two dialects' own real concerns. Had `sum.mlir` instead used one combined dialect mixing loops, arithmetic, and memory access into single, do-everything operations, no such focused, single-purpose pass could exist at all; lowering would have to be one large, tangled transformation handling every concern at once.
