# 5. Finishing Progressive Lowering: `affine` to `scf` to `llvm`, and Mountain Goat Finally Runs

**What you will understand:** how Mountain Goat's own real `affine.for` loop nests (Chapter 4) continue down through the exact same real pipeline Chapter 1 proved works -- `affine` to `scf`, `scf` to a bare control-flow graph, and on to MLIR's own `llvm` dialect, real LLVM IR, and a genuinely executed answer. This chapter also finally gives `mg.print` a real, working implementation -- Mountain Goat's own first genuinely observable, run, correct output.

**What you need to know first:** Chapter 4's own `ConvertMgToAffinePass` and Chapter 1's own five-pass `scf`-to-`llvm` pipeline. This chapter's own new ground: MLIR's real, built-in `--lower-affine` pass, and MLIR's own pre-existing runtime support library.

!!! tip "Compile and run"
    ```sh
    cd docs/part5/code
    ./build.sh        # -> ./build/mg-opt
    ./run.sh          # lower to LLVM dialect, then run with mlir-cpu-runner-18
    ```
    Also needs `mlir-cpu-runner-18` and `libmlir_runner_utils.so` / `libmlir_c_runner_utils.so` (installed with the MLIR packages). Every listing and output on this page comes from these commands (and the chapter's own embedded files).


## The real question this chapter answers

Chapter 4 deliberately stopped at `affine`/`memref`/`arith` -- genuinely lower-level than `mg`, but still well above real LLVM IR. Chapter 1 already proved, on a hand-written `scf.for` example, that `scf` lowers to `llvm` in five real passes. The real question this chapter answers: does that same real pipeline work unmodified on IR this book's own tooling produced, rather than hand-written -- and what is the one remaining real gap (`affine` itself, which Chapter 1 never had to cross) that sits between them?

## The one new real step: `affine` to `scf`

MLIR ships a real, built-in, generic pass for exactly this, needing no custom code at all -- unlike every pattern Chapter 4 had to hand-write for `mg` itself, `--lower-affine` already knows how to lower *any* dialect's `affine.for`/`affine.load`/`affine.store`, because those operations are themselves already part of MLIR's own built-in `affine` dialect:

```
./mg-opt mountain_goat_run.mlir --convert-mg-to-affine --lower-affine
```

**Real captured output (relevant excerpt):**
```mlir
func.func @add_tensors(%arg0: memref<2x2xf64>, %arg1: memref<2x2xf64>) {
  %alloc = memref.alloc() : memref<2x2xf64>
  %c0 = arith.constant 0 : index
  %c2 = arith.constant 2 : index
  %c1 = arith.constant 1 : index
  scf.for %arg2 = %c0 to %c2 step %c1 {
    %c0_0 = arith.constant 0 : index
    %c2_1 = arith.constant 2 : index
    %c1_2 = arith.constant 1 : index
    scf.for %arg3 = %c0_0 to %c2_1 step %c1_2 {
      %0 = memref.load %arg0[%arg2, %arg3] : memref<2x2xf64>
      %1 = memref.load %arg1[%arg2, %arg3] : memref<2x2xf64>
      %2 = arith.addf %0, %1 : f64
      memref.store %2, %alloc[%arg2, %arg3] : memref<2x2xf64>
    }
  }
  ...
}
```

`affine.for` became `scf.for` -- MLIR's own structured-but-no-longer-"affine" loop, with explicit lower/upper bound and step operands rather than `affine`'s own restricted index-expression language -- and, exactly as the real `affine.load`/`affine.store` operations required a restricted affine indexing scheme that plain `memref.load`/`memref.store` do not, those became plain memref accesses too. This is genuinely, precisely the same real kind of transition Chapter 1 already showed for `scf.for` itself lowering further (to a bare CFG) -- one level higher in the stack, same real idea: a more restricted, analysis-friendly structured form gives way to a more general, less restricted one as the pipeline descends.

## Giving `mg.print` a real, working implementation

Chapter 4 deliberately erased `mg.print`. This chapter gives it a real one, using MLIR's own pre-existing runtime support library (`libmlir_runner_utils.so`, already confirmed installed alongside `mlir-opt-18` since Chapter 1) rather than inventing a print mechanism from nothing. Its real, official header states the function this chapter's own lowering targets directly:

```cpp
// mlir/ExecutionEngine/RunnerUtils.h
extern "C" MLIR_RUNNERUTILS_EXPORT void printMemrefF64(int64_t rank, void *ptr);
```

Calling it correctly from generated MLIR needs one real, specific mechanism: declaring the function with MLIR's own `llvm.emit_c_interface` attribute, which tells `--convert-func-to-llvm` to emit a call to the real `_mlir_ciface_printMemrefF64` C-interface wrapper -- the one whose real ABI actually matches an unranked memref descriptor -- rather than to a plain, mismatched symbol. This same real idiom (declare a runtime function, mark it `llvm.emit_c_interface`, `memref.cast` to unranked, call it) is what MLIR's own official Toy tutorial's own later chapters use for the identical real job, cited here as precedent for the general technique, even though Toy's own chosen runtime call is a hand-rolled `printf` loop rather than this chapter's own choice to reuse `printMemrefF64` directly:

```cpp
static FlatSymbolRefAttr getOrInsertPrintMemrefF64(OpBuilder &builder,
                                                   ModuleOp module) {
  const char *name = "printMemrefF64";
  if (module.lookupSymbol<func::FuncOp>(name))
    return SymbolRefAttr::get(builder.getContext(), name);

  auto unrankedMemrefF64 =
      UnrankedMemRefType::get(builder.getF64Type(), /*memorySpace=*/0);
  auto fnType = builder.getFunctionType({unrankedMemrefF64}, {});

  OpBuilder::InsertionGuard guard(builder);
  builder.setInsertionPointToStart(module.getBody());
  auto printFunc = builder.create<func::FuncOp>(module.getLoc(), name, fnType);
  printFunc.setPrivate();
  printFunc->setAttr("llvm.emit_c_interface", builder.getUnitAttr());
  return SymbolRefAttr::get(builder.getContext(), name);
}

struct PrintOpLowering : public OpConversionPattern<mg::PrintOp> {
  using OpConversionPattern::OpConversionPattern;

  LogicalResult
  matchAndRewrite(mg::PrintOp op, OpAdaptor adaptor,
                 ConversionPatternRewriter &rewriter) const override {
    auto loc = op.getLoc();
    auto module = op->getParentOfType<ModuleOp>();
    auto printRef = getOrInsertPrintMemrefF64(rewriter, module);

    auto memrefType = llvm::cast<MemRefType>(adaptor.getInput().getType());
    auto unrankedType =
        UnrankedMemRefType::get(memrefType.getElementType(), /*memorySpace=*/0);
    Value cast =
        rewriter.create<memref::CastOp>(loc, unrankedType, adaptor.getInput());
    rewriter.create<func::CallOp>(loc, printRef, TypeRange{}, ValueRange{cast});
    rewriter.eraseOp(op);
    return success();
  }
};
```

## A second, real instance of Chapter 4's own function-boundary problem: `func.call`

Running the real test program this chapter needs -- `@main` building two tensors and calling a separate `@add_tensors` function, specifically so the real `affine.for`/`scf.for` loop survives into execution rather than folding away (the real reason Chapter 4's own constant-folding discovery made a function-argument example necessary) -- exposed one more real instance of exactly the same class of gap Chapter 4 hit with `func.func`'s own signature: `func.call @add_tensors(%0, %1)` passes tensor-typed operands too, and MLIR has a second real, built-in utility for exactly this, used the same way:

```cpp
target.addDynamicallyLegalOp<func::CallOp>([&](func::CallOp op) {
  return typeConverter.isLegal(op.getOperandTypes()) &&
         typeConverter.isLegal(op.getResultTypes());
});
...
populateCallOpTypeConversionPattern(patterns, typeConverter);
populateReturnOpTypeConversionPattern(patterns, typeConverter);
```

## Real worked example: the complete pipeline, genuinely executed

The real test program, two functions, specifically designed so the add survives as a real loop (as established above):

```mlir
func.func @add_tensors(%a: tensor<2x2xf64>, %b: tensor<2x2xf64>) {
  %0 = mg.add %a, %b : tensor<2x2xf64>, tensor<2x2xf64> -> tensor<2x2xf64>
  mg.print %0 : tensor<2x2xf64>
  func.return
}

func.func @main() {
  %0 = mg.constant dense<[[1.0, 2.0], [3.0, 4.0]]> : tensor<2x2xf64>
  %1 = mg.constant dense<[[5.0, 6.0], [7.0, 8.0]]> : tensor<2x2xf64>
  func.call @add_tensors(%0, %1) : (tensor<2x2xf64>, tensor<2x2xf64>) -> ()
  func.return
}
```

The complete real pipeline -- Chapter 4's own hand-written `mg`-to-`affine` pass, the real built-in `--lower-affine`, and Chapter 1's own exact real five-pass `scf`-to-`llvm` pipeline, unmodified:

```
./mg-opt mountain_goat_run.mlir \
  --convert-mg-to-affine --lower-affine \
  --convert-scf-to-cf --convert-arith-to-llvm \
  --finalize-memref-to-llvm --convert-func-to-llvm \
  --reconcile-unrealized-casts \
  -o mountain_goat_llvm.mlir
```

**Real captured output (excerpt -- full output is longer, real LLVM-dialect IR throughout):**
```mlir
module {
  llvm.func @malloc(i64) -> !llvm.ptr
  llvm.func private @printMemrefF64(%arg0: i64, %arg1: !llvm.ptr) attributes {llvm.emit_c_interface, sym_visibility = "private"} {
    %0 = llvm.mlir.undef : !llvm.struct<(i64, ptr)>
    %1 = llvm.insertvalue %arg0, %0[0] : !llvm.struct<(i64, ptr)>
    %2 = llvm.insertvalue %arg1, %1[1] : !llvm.struct<(i64, ptr)>
    %3 = llvm.mlir.constant(1 : index) : i64
    %4 = llvm.alloca %3 x !llvm.struct<(i64, ptr)> : (i64) -> !llvm.ptr
    llvm.store %2, %4 : !llvm.struct<(i64, ptr)>, !llvm.ptr
    llvm.call @_mlir_ciface_printMemrefF64(%4) : (!llvm.ptr) -> ()
    llvm.return
  }
  llvm.func @_mlir_ciface_printMemrefF64(!llvm.ptr) attributes {llvm.emit_c_interface, sym_visibility = "private"}
  llvm.func @add_tensors(%arg0: !llvm.ptr, %arg1: !llvm.ptr, %arg2: i64, %arg3: i64, %arg4: i64, %arg5: i64, %arg6: i64, %arg7: !llvm.ptr, %arg8: !llvm.ptr, %arg9: i64, %arg10: i64, %arg11: i64, %arg12: i64, %arg13: i64) {
    ...
    %23 = llvm.call @malloc(%22) : (i64) -> !llvm.ptr
    ...
  }
}
```

Every real pattern Chapter 1 already identified is genuinely present again: each real `memref<2x2xf64>` argument has become five separate LLVM-level arguments (the real "unpacked memref descriptor" convention), and a real `llvm.call @malloc` genuinely allocates each result buffer -- `memref.alloc` lowered to a real heap allocation, not a stack slot, exactly as `--finalize-memref-to-llvm`'s own real, documented behavior specifies.

Running this real LLVM-dialect IR directly through MLIR's own real JIT, `mlir-cpu-runner-18`, with MLIR's own real runtime support libraries supplied via `--shared-libs`:

```
mlir-cpu-runner-18 mountain_goat_llvm.mlir \
  --shared-libs=/usr/lib/llvm-18/lib/libmlir_runner_utils.so \
  --shared-libs=/usr/lib/llvm-18/lib/libmlir_c_runner_utils.so \
  -e main -entry-point-result=void
```

**Real captured output:**
```text
Unranked Memref base@ = 0x557796012ca0 rank = 2 offset = 0 sizes = [2, 2] strides = [2, 1] data =
[[6,   8],
 [10,   12]]
```

This is the real, correct answer: `[[1, 2], [3, 4]] + [[5, 6], [7, 8]] = [[6, 8], [10, 12]]`, genuinely computed by a real `affine.for`-turned-`scf.for`-turned-bare-loop running as real, JIT-compiled native code -- the first time in this book that a Mountain Goat program has been run end to end and actually produced observable output, rather than IR text this book's reader had to check by hand.

## The complete source files

The excerpts above show the parts under discussion. These files appear in `code/` and are not shown elsewhere on this page; each is embedded exactly as it exists in the repository, collapsed so the narrative stays readable.

??? note "`CMakeLists.txt`"

    ```cmake
    --8<-- "docs/part5/code/CMakeLists.txt"
    ```

??? note "`LowerToAffine.cpp`"

    ```cpp
    --8<-- "docs/part5/code/LowerToAffine.cpp"
    ```

??? note "`mg-opt.cpp`"

    ```cpp
    --8<-- "docs/part5/code/mg-opt.cpp"
    ```

## What later chapters changed

Chapters 13 and 14 changed the `LowerToAffine.cpp` shown here, in the same way described for Chapter 4 (dynamic shapes, then a runtime shape check for `mg.add`); static output is unchanged. The version in this chapter's `code/` directory is Chapter 5's own.

## Chapter summary

This chapter closed Part 3: Mountain Goat's own `affine`/`memref`/`arith` IR (Chapter 4) was carried, through one new real built-in pass (`--lower-affine`) and Chapter 1's own exact, unmodified five-pass `scf`-to-`llvm` pipeline, all the way to real LLVM-dialect IR -- confirming directly that the pipeline Chapter 1 proved on hand-written IR works identically on IR this book's own tooling actually produced. `mg.print` was given a real, working implementation for the first time, reusing MLIR's own pre-existing runtime support library (`printMemrefF64`, `llvm.emit_c_interface`) rather than inventing a mechanism from nothing, and a second real instance of Chapter 4's own function-boundary conversion problem (`func.call`, this time) was closed with another of MLIR's own built-in utilities. The result: a genuinely executed Mountain Goat program, its real, correct answer captured directly from `mlir-cpu-runner-18`'s own real output.

Deliberately out of scope, stated explicitly: this chapter still stops at `mlir-cpu-runner-18`'s own real JIT -- no standalone native executable (via `mlir-translate-18` + `clang-18`, the way Chapter 1's own `harness.c` worked) has been built for a Mountain Goat program yet; that, along with MLIR's own real `ExecutionEngine` C++ API, is Part 5's own promised subject. `mg.transpose` was not exercised in this chapter's own worked example (only `mg.add`, to keep the real loop-survival guarantee simple and direct) -- its own real lowering was already proven correct in Chapter 4.

## Self-check questions

**1. `--lower-affine` needed no hand-written pattern at all, unlike every one of Chapter 4's own `mg`-to-`affine` patterns. What real, structural difference between `mg` and `affine` explains that?**

Worked answer: `affine` is itself one of MLIR's own real, built-in dialects -- MLIR ships `--lower-affine` as a generic pass precisely because every `affine.for`/`affine.load`/`affine.store` operation, in any dialect's own IR, has the same real, fixed structure the pass already knows how to interpret. `mg.add`/`mg.transpose` are this book's own invented operations; nothing in MLIR could possibly ship a pre-built lowering for them, which is exactly why Chapter 4 had to write `AddOpLowering`/`TransposeOpLowering` by hand -- the real, general principle being that a dialect conversion needs hand-written patterns precisely for the parts of the IR that are not already standard.

**2. The chapter needed to declare `@printMemrefF64` with `llvm.emit_c_interface` rather than just calling it as an ordinary function. What real, concrete problem would omitting that attribute have caused?**

Worked answer: `printMemrefF64`'s own real, C++-level signature (from `RunnerUtils.h`) is `void printMemrefF64(int64_t rank, void *ptr)` -- two plain scalar arguments. The function MLIR's own lowering actually needs to call, `_mlir_ciface_printMemrefF64`, takes a single pointer to an `UnrankedMemRefType<double>` descriptor struct instead -- a real, different, C-interface-specific ABI. Without `llvm.emit_c_interface`, `--convert-func-to-llvm` would emit a direct call matching the first, plain signature, which does not match what `_mlir_ciface_printMemrefF64` (the symbol actually present in `libmlir_runner_utils.so`) expects -- a genuine link or runtime-crash risk, not merely a cosmetic one.

**3. Why did this chapter's own worked example need a *separate* `@add_tensors` function, called from `@main`, rather than just building the two tensors and adding them directly inside `@main`?**

Worked answer: Chapter 4's own real, honest discovery was that `AddOp::fold` fires automatically during dialect conversion's own legalization, *whenever* both of `mg.add`'s own operands are defined, within the same function, by `mg.constant`. Passing the two tensors across a real function boundary (`func.call`) is what breaks that chain: inside `@add_tensors`, `%a`/`%b` are genuine block arguments, with no real defining operation at all for the folder to inspect -- guaranteeing the real `affine.for`/`scf.for` loop genuinely survives all the way to execution, rather than silently folding away before this chapter's own pipeline had anything to run.

**4. The real captured LLVM-dialect output shows `@add_tensors` taking fourteen separate arguments for what were originally two `memref<2x2xf64>` parameters. Is this the same real phenomenon Chapter 1 first identified, or something new?**

Worked answer: the same real phenomenon, just doubled: Chapter 1 established that `--finalize-memref-to-llvm` unpacks one `memref` into five separate LLVM-level arguments (allocated pointer, aligned pointer, offset, size, stride per dimension) because LLVM IR has no single type that bundles all of that together. `@add_tensors` takes two real `memref<2x2xf64>` arguments, each independently unpacked the same real way -- five arguments each, for ten total, plus `printMemrefF64`'s own two-argument C-interface call elsewhere in the module accounting for the rest of what the excerpt shows; no new mechanism, the same real one applied twice.

**5. Why does the chapter call running this program through `mlir-cpu-runner-18` genuinely different from, and not a replacement for, the real native-executable approach Chapter 1 used (`mlir-translate-18` + `clang-18` + a C harness)?**

Worked answer: `mlir-cpu-runner-18` is itself a real, genuine JIT -- it compiles and runs the given LLVM-dialect IR in-process, through MLIR's own `ExecutionEngine`, without ever producing a standalone, independently distributable binary. Chapter 1's own approach (`mlir-translate-18` to real LLVM IR text, then `clang-18` compiling that text, linked against a real hand-written C harness) produces a genuine, ordinary native executable that could be copied to another machine and run without MLIR present at all. Both are real and both genuinely execute the same real logic, but they are not the same real thing, which is exactly why this chapter states plainly that the native-executable path, for a Mountain Goat program specifically, remains Part 5's own subject rather than claiming this chapter's own JIT run already covers it.
