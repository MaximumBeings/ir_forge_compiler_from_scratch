# 8. A Standalone Native Executable: Mountain Goat Without MLIR At Runtime

![Mountain goats on the mountain at midday](../assets/goats/ch-08.svg){ style="display:block;margin:0 auto;max-width:100%;height:auto;border-radius:6px" }

**What you will understand:** how to take a real Mountain Goat program all the way to a genuine, standalone native executable -- one that runs with no MLIR library, no JIT, no `mlir-cpu-runner-18`, present at all -- generalizing Chapter 1's own exact technique (`mlir-translate-18` + `clang-18` + a hand-written C harness) to a program this book's own tooling actually produced, for the first time.

**What you need to know first:** Chapter 1's own real "unpacked memref descriptor" calling convention, and Chapter 4's own `ConvertMgToAffinePass`. This chapter's own new ground: what that same real convention looks like for a *returned* memref, rather than only a memref argument.

!!! tip "Compile and run"
    ```sh
    cd docs/part7/code && ./build.sh      # once: Chapter 7's mg-opt
    cd ../../part8/code
    ./run.sh          # lower, translate, compile, link, run, and check what the executable links against
    ```
    Needs Chapter 7's `mg-opt`, `clang-18`, `mlir-translate-18`. Every listing and output on this page comes from these commands (and the chapter's own embedded files).


## The real question this chapter answers

Every real execution of a Mountain Goat program so far -- Chapters 5, 6, and 7 -- ran through `mlir-cpu-runner-18`, a genuine JIT: it compiles and runs LLVM-dialect IR in-process, through MLIR's own `ExecutionEngine`, but it never produces an independent binary. Chapter 1's own original real executable (`sum_demo`) needed no JIT, no MLIR runtime, nothing beyond `libc` -- a real, ordinary ELF binary, compiled once, runnable anywhere the same architecture is found. This chapter answers directly: does that same real technique work unmodified on a real Mountain Goat program, and what does the real calling convention look like when a function *returns* a tensor rather than only consuming one?

## A real Mountain Goat function, returning its own result

Every previous chapter's own worked example ended in `mg.print`, consumed inside the same function. This chapter's own real program instead returns its result directly -- the one change needed to let a real C harness read the answer back itself, the same way Chapter 1's own `harness.c` read `sum_array`'s own real return value:

```mlir
func.func @add_tensors(%a: tensor<2x2xf64>, %b: tensor<2x2xf64>) -> tensor<2x2xf64> {
  %0 = mg.add %a, %b : tensor<2x2xf64>, tensor<2x2xf64> -> tensor<2x2xf64>
  func.return %0 : tensor<2x2xf64>
}
```

Lowered through Chapter 4's own real `--convert-mg-to-affine` pass:

```
./mg-opt add_tensors.mlir --convert-mg-to-affine
```

**Real captured output:**
```mlir
module {
  func.func @add_tensors(%arg0: memref<2x2xf64>, %arg1: memref<2x2xf64>) -> memref<2x2xf64> {
    %alloc = memref.alloc() : memref<2x2xf64>
    affine.for %arg2 = 0 to 2 {
      affine.for %arg3 = 0 to 2 {
        %0 = affine.load %arg0[%arg2, %arg3] : memref<2x2xf64>
        %1 = affine.load %arg1[%arg2, %arg3] : memref<2x2xf64>
        %2 = arith.addf %0, %1 : f64
        affine.store %2, %alloc[%arg2, %arg3] : memref<2x2xf64>
      }
    }
    return %alloc : memref<2x2xf64>
  }
}
```

Nothing new was needed in `ConvertMgToAffinePass` itself for this -- `mg.add`'s own lowering pattern was already correct; the only real change is that this chapter's own program hands the add's own result straight to `func.return` instead of `mg.print`.

## Continuing to real LLVM-dialect IR, and reading the real returned calling convention

Chapter 1's own exact five-pass pipeline, unmodified, continues the real lowering:

```
./mg-opt add_tensors.mlir --convert-mg-to-affine --lower-affine --convert-scf-to-cf \
  --convert-arith-to-llvm --finalize-memref-to-llvm --convert-func-to-llvm \
  --reconcile-unrealized-casts -o add_tensors_llvm.mlir
```

**Real captured output (signature only -- full output is longer):**
```mlir
llvm.func @add_tensors(%arg0: !llvm.ptr, %arg1: !llvm.ptr, %arg2: i64, %arg3: i64, %arg4: i64,
                       %arg5: i64, %arg6: i64, %arg7: !llvm.ptr, %arg8: !llvm.ptr, %arg9: i64,
                       %arg10: i64, %arg11: i64, %arg12: i64, %arg13: i64)
    -> !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> {
  ...
  llvm.return %32 : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
}
```

Chapter 1's own real five-argument unpacking is genuinely here again, doubled for two memref operands (fourteen scalar arguments total) -- but the real, new fact this chapter needed is the *return* type: `!llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>`. Rather than unpacking a memref result into separate scalar return values (which LLVM IR's own calling convention does not support -- a function returns at most one value), `--finalize-memref-to-llvm` packs the exact same five real fields -- allocated pointer, aligned pointer, offset, sizes, strides -- into one real LLVM struct, returned by value.

## The real C harness: a matching struct, not five more scalar parameters

Chapter 1's own harness declared five separate C parameters for one memref *argument*. This chapter's own harness needs a real C `struct` instead, laid out to match the LLVM struct's own real field order and types exactly:

```c
#include <stdint.h>
#include <stdio.h>

typedef struct {
    double *allocated;
    double *aligned;
    int64_t offset;
    int64_t sizes[2];
    int64_t strides[2];
} Memref2D;

extern Memref2D add_tensors(double *allocated0, double *aligned0, int64_t offset0,
                             int64_t size0_0, int64_t size0_1,
                             int64_t stride0_0, int64_t stride0_1,
                             double *allocated1, double *aligned1, int64_t offset1,
                             int64_t size1_0, int64_t size1_1,
                             int64_t stride1_0, int64_t stride1_1);

int main(void) {
    double a[4] = {1.0, 2.0, 3.0, 4.0};
    double b[4] = {5.0, 6.0, 7.0, 8.0};

    Memref2D result = add_tensors(a, a, 0, 2, 2, 2, 1,
                                   b, b, 0, 2, 2, 2, 1);

    printf("add_tensors([[1,2],[3,4]], [[5,6],[7,8]]) =\n");
    for (int64_t i = 0; i < result.sizes[0]; i++) {
        for (int64_t j = 0; j < result.sizes[1]; j++) {
            printf("%g ", result.aligned[i * result.strides[0] + j * result.strides[1]]);
        }
        printf("\n");
    }
    return 0;
}
```

`Memref2D`'s own five real fields -- `allocated`, `aligned`, `offset`, `sizes[2]`, `strides[2]` -- are genuinely the same five real fields Chapter 1 first identified as separate function arguments, now a single C struct this chapter's own harness reads directly: `result.aligned[i * result.strides[0] + j * result.strides[1]]` is the real, general strided-access formula every real memref descriptor supports, applied here by hand in C rather than by an `affine.load`.

## Compiling to real LLVM IR, then a genuine native executable

```
mlir-translate-18 --mlir-to-llvmir add_tensors_llvm.mlir -o add_tensors.ll
```

**Real captured output excerpt:**
```llvm
define { ptr, ptr, i64, [2 x i64], [2 x i64] } @add_tensors(ptr %0, ptr %1, i64 %2, i64 %3, i64 %4, i64 %5, i64 %6, ptr %7, ptr %8, i64 %9, i64 %10, i64 %11, i64 %12, i64 %13) {
  ...
}
```

Genuinely real LLVM IR, the struct return spelled out exactly as MLIR's own translator produced it -- no hand-editing.

```
clang-18 -c add_tensors.ll -o add_tensors.o
clang-18 -Wall -Wextra -c harness.c -o harness.o
clang-18 add_tensors.o harness.o -o add_tensors_demo
```

**Real captured compiler output:**
```text
warning: overriding the module target triple with x86_64-pc-linux-gnu [-Woverride-module]
1 warning generated.
```

The exact same real, harmless warning Chapter 1 saw, for the exact same real reason: `mlir-translate-18` writes no target-triple metadata, and Clang fills it in with this host's own real triple.

```
./add_tensors_demo
```

**Real captured program output:**
```text
add_tensors([[1,2],[3,4]], [[5,6],[7,8]]) =
6 8
10 12
```

The real, correct answer -- `[[1, 2], [3, 4]] + [[5, 6], [7, 8]] = [[6, 8], [10, 12]]` -- genuinely computed by a real, standalone ELF binary.

## Confirming it is genuinely standalone

```
ldd add_tensors_demo
```

**Real captured output:**
```text
linux-vdso.so.1 (0x00007f158f53b000)
libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f158f200000)
/lib64/ld-linux-x86-64.so.2 (0x00007f158f53d000)
```

Genuinely, only `libc` -- no `libMLIR*.so`, no `libmlir_runner_utils.so`, nothing from MLIR's own runtime at all. This is the real, concrete difference this chapter set out to demonstrate: Chapters 5 through 7's own `mlir-cpu-runner-18` runs require the real MLIR toolchain to be present on whatever machine runs them; `add_tensors_demo` does not -- it could be copied to any other real x86_64 Linux machine, with no MLIR installed whatsoever, and would run identically.

## What later chapters changed

Chapter 8's `harness.c` is linked unmodified by Chapters 11 and 12 (against a CPU stub runtime), and a byte-identical copy (`static_harness.c`) is used by the Chapter 15 test `execution/static-add-runs`, which rebuilds and reruns this chapter's static `add_tensors` on both lowering paths. Nothing in this chapter's own code has changed.

## Chapter summary

This chapter generalized Chapter 1's own exact real technique -- `mlir-translate-18` to real LLVM IR, `clang-18` compiling it, linked against a real hand-written C harness -- to a genuine Mountain Goat program for the first time, closing an open item this book has carried since Chapter 4. The one real, new fact this chapter needed, not present in Chapter 1's own original example: a *returned* memref packs its own five real descriptor fields into a single LLVM struct, returned by value, rather than unpacking into separate scalar arguments the way a memref *parameter* does -- met on the C side with a matching `struct`, not five more parameters. The resulting binary was confirmed, directly via `ldd`, to depend on nothing but `libc` -- a genuinely standalone artifact, distinct in kind from every prior chapter's own JIT-based execution.

Deliberately out of scope, stated explicitly: this chapter's own harness reads the result with hand-written C, specific to this one function's own known shape (`2x2`, `f64`) -- a general-purpose C library for reading arbitrary real memref descriptors is not built here. MLIR's own real C++ `ExecutionEngine` API -- a third, genuinely different real execution mechanism from both `mlir-cpu-runner-18` and this chapter's own ahead-of-time compilation -- has not been used yet.

## Self-check questions

**1. Chapter 1's own `harness.c` declared five separate `int32_t`/pointer parameters for one memref *argument*. This chapter's own harness instead declares one C `struct` for a memref *result*. Why does an argument and a result need different real C-side shapes for what is, in both cases, "a memref descriptor"?**

Worked answer: LLVM IR's own calling convention allows a function to take any number of separate scalar parameters, which is exactly how `--finalize-memref-to-llvm` unpacks a memref argument -- five separate values, passed the ordinary way. A function's own *return value*, by contrast, is a single value in LLVM IR's own real model; there is no mechanism for "returning five separate things." Packing the same five real fields into one struct, returned by value, is the only real way to get all five fields back out of a single return -- which is exactly why the C side needs a matching `struct` for a result, but plain separate parameters for an argument.

**2. Why did this chapter need no new code at all in `ConvertMgToAffinePass` (Chapter 4's own pass) to support a function that returns a tensor, when earlier gaps (function signatures, `func.call`) each needed real, new conversion-pattern work?**

Worked answer: `mg.add`'s own lowering pattern already produces a real `memref` value as its result, regardless of what the surrounding function does with it afterward -- whether that value is consumed by `mg.print`, passed to another function, or returned directly was never something `AddOpLowering` itself needed to know or care about. The real, already-registered `func.func`/`func.return` signature-conversion machinery (from Chapter 4's own `populateFunctionOpInterfaceTypeConversionPattern` and the dynamically-legal `func::ReturnOp` check) already covers a function returning a converted type, since a return value is conceptually no different, to that real machinery, from a return type needing conversion as part of the function's own signature.

**3. The chapter confirms the resulting binary is standalone by running `ldd` and finding only `libc`. Why would that same real check, run against one of Chapter 5's own `mlir-cpu-runner-18` invocations, not make sense as a comparison?**

Worked answer: `mlir-cpu-runner-18` is not itself a program this book compiled from Mountain Goat source -- it is a real, pre-built MLIR tool that reads LLVM-dialect IR as its own input at runtime and JIT-compiles it in-process. Running `ldd` on `mlir-cpu-runner-18` would show its own real, fixed set of MLIR/LLVM library dependencies, true regardless of which Mountain Goat program it happens to be given -- it says nothing about whether *that particular program* depends on MLIR, since the program itself was never turned into an independent binary at all; it only ever exists as IR text handed to the JIT.

**4. Why does this chapter's own harness compute `result.aligned[i * result.strides[0] + j * result.strides[1]]` rather than something simpler, like `result.aligned[i][j]` or `result.aligned[i * 2 + j]`?**

Worked answer: `result.aligned[i][j]` is not real, valid C for a flat `double *` -- `aligned` is a pointer to the buffer's own first element, not a pointer to an array of rows. `result.aligned[i * 2 + j]` would happen to produce the correct real answer for this one `2x2` example, but only by coincidence: it hard-codes the real stride (`2`) as a literal, rather than reading the real stride this specific memref descriptor actually reports. The general formula the harness actually uses is the real, same one every genuine memref consumer (including `affine.load` itself) relies on -- multiply each index by its own dimension's real stride and sum -- correct for any real shape, not just this chapter's own `2x2` example.

**5. This chapter's own real program never calls `mg.print`, unlike every previous chapter's own worked example. What real, concrete problem would calling `mg.print` here have reintroduced, that returning the tensor directly avoided?**

Worked answer: Chapter 5's own real `mg.print` lowering calls `printMemrefF64`, declared with `llvm.emit_c_interface` so `--convert-func-to-llvm` routes the call through `_mlir_ciface_printMemrefF64` -- a real, specific symbol that only exists inside `libmlir_runner_utils.so`. Linking a standalone binary against that call would have reintroduced exactly the real MLIR-runtime dependency this chapter's own `ldd` check was built to rule out; returning the tensor directly, and reading it with plain, dependency-free C instead, is what let this chapter's own binary end up depending on nothing but `libc`.
