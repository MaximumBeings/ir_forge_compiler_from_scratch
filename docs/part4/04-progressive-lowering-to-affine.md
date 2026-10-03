# 4. Progressive Lowering: Mountain Goat to `affine`, Two Real Ways

![Mountain goats in space helmets on the Moon](../assets/goats/ch-04.svg){ style="display:block;margin:0 auto;max-width:100%;height:auto;border-radius:6px" }

**What you will understand:** how a tensor-based toy op genuinely becomes a real loop nest over real memory -- the concrete, code-level answer to the value-semantics-to-buffer-semantics gap every real MLIR pipeline that uses `tensor` types up high and `affine`/`memref` down low has to cross somewhere. This chapter crosses it twice: once by hand, fully understood step by step, and once by reaching for MLIR's own real, built-in production machinery -- and shows, honestly, exactly where the second attempt stops short.

**What you need to know first:** Chapters 2 and 3's own `mg` dialect and its real canonicalization patterns. This chapter's own new vocabulary -- dialect conversion's real `ConversionTarget`/`TypeConverter`/`ConversionPattern`, and real bufferization -- was introduced only conceptually in Chapter 3; it is used for real, for the first time, here.

!!! tip "Compile and run"
    ```sh
    cd docs/part4/code
    ./build.sh        # -> ./build/mg-opt (with --convert-mg-to-affine)
    ./run.sh          # lowering to affine/memref, and the failed one-shot-bufferize attempt
    ```
    Same prerequisites as Chapter 2. `run.sh` includes the attempt this chapter shows **failing**; that failure is the expected result. Every listing and output on this page comes from these commands (and the chapter's own embedded files).


## The real question this chapter answers

Every Mountain Goat example so far has stayed inside one dialect, `mg` itself, operating on `tensor` types -- MLIR's own value-semantic array type, where an "add" produces a brand-new logical value, not a write into existing memory. MLIR's own real `affine` dialect, the real target Part 3 of this book commits to, works the other way: `affine.for`, `affine.load`, `affine.store` all operate on `memref` -- MLIR's own buffer-semantic type, an actual region of memory a real loop actually reads from and writes into. A `tensor<2x2xf64>` and a `memref<2x2xf64>` describe the same real shape and element type, but they are not interchangeable: nothing in `affine.load`'s own real definition accepts a `tensor` operand. This chapter answers, concretely, how Mountain Goat's own operations actually cross that gap -- not as a diagram, but as real, compiling, running C++.

## Two real approaches, both attempted honestly

**Approach A**, built fully in this chapter: a single, real, hand-written dialect-conversion pass that does both jobs in one pattern per operation -- allocates a real `memref` for each `mg` op's own result, and emits the real `affine.for`/`affine.load`/`affine.store` operations that compute into it, as that one operation is converted.

**Approach B**, attempted directly against MLIR's own real, built-in production bufferization pass (`--one-shot-bufferize`) rather than hand-rolled: run exactly as `mlir-opt-18` itself would run it, against Mountain Goat's own real `mg` ops, with the real result -- success or failure -- captured honestly, whichever it turns out to be.

## Approach A: a real, hand-written `ConvertMgToAffinePass`

### The real type gap, bridged by a real `TypeConverter`

MLIR's own real dialect-conversion framework (introduced conceptually in Chapter 3, cited from `mlir/docs/DialectConversion.md`) needs a real `TypeConverter` to know how a `tensor<2x2xf64>` operand should look once converted. This chapter's own version is deliberately narrow -- it only has to handle the static, rank-2 shapes this book's own worked examples actually use:

```cpp
static MemRefType convertTensorToMemref(RankedTensorType type) {
  return MemRefType::get(type.getShape(), type.getElementType());
}

struct MgToAffineTypeConverter : public TypeConverter {
  MgToAffineTypeConverter() {
    addConversion([](Type type) { return type; });
    addConversion([](RankedTensorType type) -> Type {
      return convertTensorToMemref(type);
    });
  }
};
```

### Three real `ConversionPattern`s, one per `mg` operation that computes something

```cpp
struct ConstantOpLowering : public OpConversionPattern<mg::ConstantOp> {
  using OpConversionPattern::OpConversionPattern;

  LogicalResult
  matchAndRewrite(mg::ConstantOp op, OpAdaptor adaptor,
                 ConversionPatternRewriter &rewriter) const override {
    auto loc = op.getLoc();
    auto tensorType = llvm::cast<RankedTensorType>(op.getResult().getType());
    auto memrefType = convertTensorToMemref(tensorType);
    auto alloc = rewriter.create<memref::AllocOp>(loc, memrefType);

    llvm::SmallVector<double> values;
    for (auto v : op.getValue().getValues<llvm::APFloat>())
      values.push_back(v.convertToDouble());

    auto shape = tensorType.getShape();
    int64_t idx = 0;
    for (int64_t i = 0; i < shape[0]; ++i) {
      for (int64_t j = 0; j < shape[1]; ++j) {
        Value cst = rewriter.create<arith::ConstantOp>(
            loc, rewriter.getF64FloatAttr(values[idx++]));
        Value iIdx = rewriter.create<arith::ConstantIndexOp>(loc, i);
        Value jIdx = rewriter.create<arith::ConstantIndexOp>(loc, j);
        rewriter.create<affine::AffineStoreOp>(loc, cst, alloc,
                                               ValueRange{iIdx, jIdx});
      }
    }

    rewriter.replaceOp(op, alloc.getResult());
    return success();
  }
};
```

`ConstantOp` lowers to a real `memref.alloc` plus a fully-unrolled sequence of real `affine.store`s, one per element -- genuinely correct only because this chapter's own worked examples use small, static shapes; a general lowering would emit a real loop nest here too, reading the constant's own values from a global instead of unrolling.

```cpp
struct AddOpLowering : public OpConversionPattern<mg::AddOp> {
  using OpConversionPattern::OpConversionPattern;

  LogicalResult
  matchAndRewrite(mg::AddOp op, OpAdaptor adaptor,
                 ConversionPatternRewriter &rewriter) const override {
    auto loc = op.getLoc();
    auto tensorType = llvm::cast<RankedTensorType>(op.getResult().getType());
    auto memrefType = convertTensorToMemref(tensorType);
    auto alloc = rewriter.create<memref::AllocOp>(loc, memrefType);
    auto shape = tensorType.getShape();

    Value lhs = adaptor.getLhs();
    Value rhs = adaptor.getRhs();

    affine::buildAffineLoopNest(
        rewriter, loc, {0, 0}, {shape[0], shape[1]}, {1, 1},
        [&](OpBuilder &nestedBuilder, Location nestedLoc, ValueRange ivs) {
          Value lhsVal =
              nestedBuilder.create<affine::AffineLoadOp>(nestedLoc, lhs, ivs);
          Value rhsVal =
              nestedBuilder.create<affine::AffineLoadOp>(nestedLoc, rhs, ivs);
          Value sum = nestedBuilder.create<arith::AddFOp>(nestedLoc, lhsVal, rhsVal);
          nestedBuilder.create<affine::AffineStoreOp>(nestedLoc, sum, alloc, ivs);
        });

    rewriter.replaceOp(op, alloc.getResult());
    return success();
  }
};
```

`AddOp` genuinely needs a loop -- MLIR's own real `mlir::affine::buildAffineLoopNest` utility (the exact real, official helper MLIR's own Toy tutorial's own affine-lowering chapter uses for the same real job, cited here as precedent) builds a perfect, real `affine.for` nest and hands this chapter's own callback one `OpBuilder` per innermost iteration -- `adaptor.getLhs()`/`adaptor.getRhs()` are already the *converted* (memref) operands, supplied by the conversion framework itself, not this chapter's own code.

```cpp
struct TransposeOpLowering : public OpConversionPattern<mg::TransposeOp> {
  using OpConversionPattern::OpConversionPattern;

  LogicalResult
  matchAndRewrite(mg::TransposeOp op, OpAdaptor adaptor,
                 ConversionPatternRewriter &rewriter) const override {
    auto loc = op.getLoc();
    auto tensorType = llvm::cast<RankedTensorType>(op.getResult().getType());
    auto memrefType = convertTensorToMemref(tensorType);
    auto alloc = rewriter.create<memref::AllocOp>(loc, memrefType);
    auto shape = tensorType.getShape();

    Value input = adaptor.getInput();

    affine::buildAffineLoopNest(
        rewriter, loc, {0, 0}, {shape[0], shape[1]}, {1, 1},
        [&](OpBuilder &nestedBuilder, Location nestedLoc, ValueRange ivs) {
          Value i = ivs[0];
          Value j = ivs[1];
          Value loaded = nestedBuilder.create<affine::AffineLoadOp>(
              nestedLoc, input, ValueRange{j, i});
          nestedBuilder.create<affine::AffineStoreOp>(nestedLoc, loaded, alloc,
                                                       ValueRange{i, j});
        });

    rewriter.replaceOp(op, alloc.getResult());
    return success();
  }
};
```

`TransposeOp`'s own real transpose is nothing more than the index swap between load and store: iterating over the *output* shape, `result[i, j]` is read from `input[j, i]`.

```cpp
struct PrintOpLowering : public OpConversionPattern<mg::PrintOp> {
  using OpConversionPattern::OpConversionPattern;

  LogicalResult
  matchAndRewrite(mg::PrintOp op, OpAdaptor adaptor,
                 ConversionPatternRewriter &rewriter) const override {
    rewriter.eraseOp(op);
    return success();
  }
};
```

`mg.print` is deliberately erased rather than lowered to a real print call -- wiring it to an actual runtime print function needs real native execution machinery this book has not built yet (Part 5's own real subject). Stated honestly rather than silently dropped without comment.

### A real gap this chapter's own first attempt hit directly: function signatures

The first real version of this chapter's own pass made every `mg` operation illegal and ran it. It failed, with a genuine, instructive error:

```text
error: failed to legalize unresolved materialization from 'tensor<2x2xf64>' to 'memref<2x2xf64>' that remained live after conversion
  %0 = mg.add %a, %b : tensor<2x2xf64>, tensor<2x2xf64> -> tensor<2x2xf64>
       ^
note: see current operation: %0 = "builtin.unrealized_conversion_cast"(%arg1) : (tensor<2x2xf64>) -> memref<2x2xf64>
```

The real cause: marking `mg.add`'s own *operation* illegal says nothing about a *function's own block arguments* -- `%a: tensor<2x2xf64>` is a `func.func` argument, never touched by patterns that only match `mg` ops. The real, correct fix needs `func.func`'s own signature to be converted too, using MLIR's own real, built-in utility for exactly this:

```cpp
void runOnOperation() override {
  MgToAffineTypeConverter typeConverter;
  ConversionTarget target(getContext());
  target.addLegalDialect<affine::AffineDialect, memref::MemRefDialect,
                         arith::ArithDialect>();
  target.addIllegalDialect<mg::MgDialect>();

  target.addDynamicallyLegalOp<func::FuncOp>([&](func::FuncOp op) {
    return typeConverter.isSignatureLegal(op.getFunctionType()) &&
           typeConverter.isLegal(&op.getBody());
  });
  target.addDynamicallyLegalOp<func::ReturnOp>([&](func::ReturnOp op) {
    return typeConverter.isLegal(op.getOperandTypes());
  });

  RewritePatternSet patterns(&getContext());
  patterns.add<ConstantOpLowering, AddOpLowering, TransposeOpLowering,
              PrintOpLowering>(typeConverter, &getContext());
  populateFunctionOpInterfaceTypeConversionPattern<func::FuncOp>(patterns,
                                                                 typeConverter);

  if (failed(applyPartialConversion(getOperation(), target,
                                    std::move(patterns))))
    signalPassFailure();
}
```

`target.addDynamicallyLegalOp<func::FuncOp>` is the real, precise statement of the fix: a `func.func` is only legal once its own signature is *already* in terms of the converted (memref) types -- and `populateFunctionOpInterfaceTypeConversionPattern`, MLIR's own real, built-in utility, is what actually performs that conversion, rewriting every block argument's own type in place.

### Wiring the real pass into `mg-opt`

```cpp
#include "mg/MgDialect.h"

#include "mlir/Dialect/Affine/IR/AffineOps.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Bufferization/IR/Bufferization.h"
#include "mlir/Dialect/Bufferization/Transforms/Passes.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/MemRef/IR/MemRef.h"
#include "mlir/IR/DialectRegistry.h"
#include "mlir/InitAllDialects.h"
#include "mlir/Tools/mlir-opt/MlirOptMain.h"
#include "mlir/Transforms/Passes.h"

namespace mg {
void registerConvertMgToAffinePass();
}

int main(int argc, char **argv) {
  mlir::registerCanonicalizerPass();
  mlir::registerCSEPass();
  mg::registerConvertMgToAffinePass();
  mlir::bufferization::registerBufferizationPasses();

  mlir::DialectRegistry registry;
  registry.insert<mlir::func::FuncDialect, mlir::affine::AffineDialect,
                  mlir::memref::MemRefDialect, mlir::arith::ArithDialect,
                  mlir::bufferization::BufferizationDialect>();
  registry.insert<mg::MgDialect>();
  return mlir::asMainReturnCode(
      mlir::MlirOptMain(argc, argv, "Mountain Goat (mg) dialect driver\n", registry));
}
```

```cmake
add_library(MgLowerToAffine lib/LowerToAffine.cpp)
add_dependencies(MgLowerToAffine MgOpsIncGen)
target_link_libraries(MgLowerToAffine PUBLIC
  MgDialect
  MLIRIR
  MLIRPass
  MLIRTransforms
  MLIRAffineDialect
  MLIRMemRefDialect
  MLIRArithDialect
  MLIRFuncDialect
)

add_executable(mg-opt tools/mg-opt.cpp)
target_link_libraries(mg-opt PRIVATE
  MgDialect
  MgLowerToAffine
  MLIRIR
  MLIRFuncDialect
  MLIROptLib
  MLIRParser
  MLIRSupport
  MLIRTransforms
  MLIRAffineDialect
  MLIRMemRefDialect
  MLIRArithDialect
  MLIRBufferizationDialect
  MLIRBufferizationTransforms
)
```

```
cmake --build build -j4
```

**Real captured output:**
```text
[ 50%] Built target MgOpsIncGen
[ 60%] Built target MgDialect
[ 80%] Built target MgLowerToAffine
[100%] Built target mg-opt
```

## Real worked example: a genuine `affine.for` loop nest, not folded away

A function taking two real tensor *arguments* (deliberately not constants, so Chapter 3's own constant-folder has nothing to fold -- the real loop-nest codegen is what this example is for):

```mlir
func.func @add_tensors(%a: tensor<2x2xf64>, %b: tensor<2x2xf64>) {
  %0 = mg.add %a, %b : tensor<2x2xf64>, tensor<2x2xf64> -> tensor<2x2xf64>
  mg.print %0 : tensor<2x2xf64>
  func.return
}
```

```
./mg-opt add_tensors.mlir --convert-mg-to-affine
```

**Real captured output (cloud sandbox, this chapter's own rebuilt `mg-opt`):**
```text
module {
  func.func @add_tensors(%arg0: memref<2x2xf64>, %arg1: memref<2x2xf64>) {
    %alloc = memref.alloc() : memref<2x2xf64>
    affine.for %arg2 = 0 to 2 {
      affine.for %arg3 = 0 to 2 {
        %0 = affine.load %arg0[%arg2, %arg3] : memref<2x2xf64>
        %1 = affine.load %arg1[%arg2, %arg3] : memref<2x2xf64>
        %2 = arith.addf %0, %1 : f64
        affine.store %2, %alloc[%arg2, %arg3] : memref<2x2xf64>
      }
    }
    return
  }
}
```

The real `affine.for` loop nest is genuinely there, exactly as `AddOpLowering` was written to produce -- and the function's own arguments are genuinely `memref<2x2xf64>` now, not `tensor<2x2xf64>`, confirming the signature-conversion fix above actually took effect.

## A real, honest surprise: Chapter 3's own folder fires *during* this chapter's lowering too

Running this chapter's own pass against a program built entirely from `mg.constant`s (rather than function arguments) produces something worth explaining directly rather than glossing over:

```mlir
func.func @main() {
  %0 = mg.constant dense<[[1.0, 2.0], [3.0, 4.0]]> : tensor<2x2xf64>
  %1 = mg.constant dense<[[5.0, 6.0], [7.0, 8.0]]> : tensor<2x2xf64>
  %2 = mg.add %0, %1 : tensor<2x2xf64>, tensor<2x2xf64> -> tensor<2x2xf64>
  %3 = mg.transpose %2 : tensor<2x2xf64> to tensor<2x2xf64>
  mg.print %3 : tensor<2x2xf64>
  func.return
}
```

```
./mg-opt mountain_goat.mlir --convert-mg-to-affine
```

**Real captured output (relevant excerpt -- full output is longer):**
```text
module {
  func.func @main() {
    %alloc = memref.alloc() : memref<2x2xf64>
    ... (four affine.store ops writing 1.0, 2.0, 3.0, 4.0)
    %alloc_9 = memref.alloc() : memref<2x2xf64>
    ... (four affine.store ops writing 5.0, 6.0, 7.0, 8.0)
    %alloc_22 = memref.alloc() : memref<2x2xf64>
    ... (four affine.store ops writing 6.0, 8.0, 10.0, 12.0)
    %alloc_35 = memref.alloc() : memref<2x2xf64>
    affine.for %arg0 = 0 to 2 {
      affine.for %arg1 = 0 to 2 {
        %0 = affine.load %alloc_22[%arg1, %arg0] : memref<2x2xf64>
        affine.store %0, %alloc_35[%arg0, %arg1] : memref<2x2xf64>
      }
    }
    return
  }
}
```

No `arith.addf` appears anywhere, and `%alloc_22` already holds `[[6, 8], [10, 12]]` -- the real, correctly-summed result -- despite this chapter's own `AddOpLowering` pattern never once having built an `affine.for` loop for it. What genuinely happened: MLIR's own dialect-conversion driver tries an operation's own registered `fold()` hook as a first, cheaper legalization attempt before reaching for a full `ConversionPattern` -- so `AddOp::fold` (written in Chapter 3, for an entirely different purpose: the `--canonicalize` pass) fired here too, folding the `mg.add` of two `mg.constant`s into one new `mg.constant` *before* `AddOpLowering` ever got the chance to run. The fresh `mg.constant` that folding materializes (via Chapter 3's own `MgDialect::materializeConstant`) is then what actually gets matched by `ConstantOpLowering` instead. This is a genuine, real consequence of how the two chapters' own real mechanisms compose -- not a bug, and not something this chapter's own code made happen on purpose.

Running `--canonicalize` immediately before `--convert-mg-to-affine` makes this explicit rather than implicit, and produces visibly smaller real output -- the constant-fold and the double-transpose-adjacent cleanup both already done before lowering ever starts:

```
./mg-opt mountain_goat.mlir --canonicalize --convert-mg-to-affine
```

**Real captured output:**
```text
module {
  func.func @main() {
    %alloc = memref.alloc() : memref<2x2xf64>
    %cst = arith.constant 6.000000e+00 : f64
    ...
    affine.store %cst, %alloc[%c0, %c0_0] : memref<2x2xf64>
    ... (three more stores: 8.0, 10.0, 12.0)
    %alloc_9 = memref.alloc() : memref<2x2xf64>
    affine.for %arg0 = 0 to 2 {
      affine.for %arg1 = 0 to 2 {
        %0 = affine.load %alloc[%arg1, %arg0] : memref<2x2xf64>
        affine.store %0, %alloc_9[%arg0, %arg1] : memref<2x2xf64>
      }
    }
    return
  }
}
```

Two real `memref.alloc`s instead of four -- the addition is gone before lowering even starts, confirmed directly rather than assumed.

## Approach B: reaching for MLIR's own real, built-in `--one-shot-bufferize`

MLIR's own official documentation names its real, built-in bufferization pass directly:

> "The most important bufferization pass is *One-Shot Bufferize*: This pass rewrites `tensor` IR to `memref` IR... **Extensible** via an op interface: All ops that implement `BufferizableOpInterface` can be bufferized." (`mlir/docs/Bufferization.md`)

Running it directly against Mountain Goat's own real `mg` ops -- genuinely attempted, not assumed to fail -- is this chapter's own honest second real experiment:

```
./mg-opt mountain_goat.mlir --one-shot-bufferize
```

**Real captured output:**
```text
mountain_goat.mlir:2:8: error: op was not bufferized
  %0 = mg.constant dense<[[1.0, 2.0], [3.0, 4.0]]> : tensor<2x2xf64>
       ^
mountain_goat.mlir:2:8: note: see current operation: %0 = "mg.constant"() <{value = dense<[[1.000000e+00, 2.000000e+00], [3.000000e+00, 4.000000e+00]]> : tensor<2x2xf64>}> : () -> tensor<2x2xf64>
```

This is a real, honest negative result, not a workaround or a hidden failure: MLIR's own documentation states plainly what Approach A's own hand-written patterns had to do manually -- that One-Shot Bufferize can only bufferize an operation that genuinely implements `BufferizableOpInterface`, and nothing about `mg.constant`'s own real ODS definition (Chapter 2) does. The real, official extension path exists and is named directly in the same documentation:

> "Custom ops can be bufferized if they implement `BufferizableOpInterface`. Users must at least implement the following interface methods... `bufferizesToMemoryRead`... `bufferizesToMemoryWrite`..." (`mlir/docs/Bufferization.md`)

Implementing that real interface for `mg.constant`/`mg.add`/`mg.transpose` is genuinely more work than this chapter's own hand-written `ConvertMgToAffinePass` needed -- not less -- because it requires correctly answering real, whole-function-level questions about aliasing and in-place bufferization that Approach A's own single-pattern-per-op scheme simply never has to ask. That real work is deliberately left for Part 4's own already-promised subject, "real bufferization," rather than attempted here as an afterthought.

## The complete source files

The excerpts above show the parts under discussion. These files appear in `code/` and are not shown elsewhere on this page; each is embedded exactly as it exists in the repository, collapsed so the narrative stays readable.

??? note "`CMakeLists.txt`"

    ```cmake
    --8<-- "docs/part4/code/CMakeLists.txt"
    ```

## What later chapters changed

Chapters 13 and 14 changed `LowerToAffine.cpp`: it now supports dynamic shapes (runtime extents via `memref.dim`, dynamic allocation, operand-bound loops) and, for `mg.add`, emits a runtime shape check (`cf.assert`) before the loop. Static programs take exactly the old code path: the output of `--convert-mg-to-affine` on a static `mg.add` is byte-identical to the one this book stored in Chapter 10, and Chapter 15's suite asserts it stays free of any check. The version in this chapter's `code/` directory is the original.

## Chapter summary

This chapter crossed the real tensor-to-memref gap `affine.for`/`affine.load`/`affine.store` require, by hand: a real `TypeConverter`, four real `ConversionPattern`s (one of which, `mg.print`, deliberately erases rather than lowers), and a real fix for a real gap this chapter's own first attempt hit directly (function signatures need their own real conversion, via `populateFunctionOpInterfaceTypeConversionPattern`). Running the resulting real pass produced a genuine `affine.for` loop nest for `mg.add`'s general case, and revealed a genuine, honest interaction with Chapter 3's own constant-folder firing automatically during conversion's own legalization attempt -- a real consequence of how MLIR's own dialect-conversion driver actually works, not a scripted demonstration. A second real attempt, reaching directly for MLIR's own built-in `--one-shot-bufferize` instead of hand-written patterns, produced a real, honest failure, with the real documented reason (`BufferizableOpInterface`) and the real, concrete extra work implementing it would require, both stated directly rather than smoothed over.

Deliberately out of scope, stated explicitly: `mg.print` is erased, not lowered to a real print call -- no native execution of this chapter's own lowered output has happened yet. `BufferizableOpInterface` is not implemented for any `mg` operation; One-Shot Bufferize remains a real, documented path not yet taken. Lowering from `affine` down to `scf` and `llvm` -- generalizing Chapter 1's own exact pipeline -- has not happened yet either; this chapter stops at `affine`/`memref`/`arith`.

## Self-check questions

**1. Why did the chapter's own first version of `ConvertMgToAffinePass` fail with an `unrealized_conversion_cast` error on `add_tensors.mlir`, specifically, rather than on `mountain_goat.mlir`?**

Worked answer: `mountain_goat.mlir`'s own tensors all genuinely originate from `mg.constant`, an operation this chapter's own `ConstantOpLowering` pattern directly converts -- no block argument is ever involved. `add_tensors.mlir`'s own two tensors are real `func.func` arguments, whose type the conversion framework has no pattern to change unless `func.func` itself is addressed -- exposing the real gap (function signatures) that `mountain_goat.mlir`'s own all-internal structure happened not to exercise.

**2. The chapter's own `ConstantOpLowering` fully unrolls its stores rather than emitting a real `affine.for` loop, while `AddOpLowering` and `TransposeOpLowering` both use `buildAffineLoopNest`. What real, principled reason justifies that difference, rather than it being arbitrary?**

Worked answer: `ConstantOp`'s own real values come from a compile-time-known `DenseElementsAttr` -- there is no real per-iteration *computation*, only a fixed sequence of literal values to place into memory, genuinely indexable without a loop induction variable at all. `AddOp` and `TransposeOp` both perform a real, uniform operation (a load-load-add-store, or a load-store with swapped indices) that is identical at every index -- exactly the situation a real loop exists to express once instead of unrolling, which is what `buildAffineLoopNest` is for.

**3. Running `--convert-mg-to-affine` alone on `mountain_goat.mlir` produced no `arith.addf` at all, yet the real captured output is still correct. Why does calling this a bug in `ConvertMgToAffinePass` be the wrong conclusion?**

Worked answer: the real, correct sum (`[[6, 8], [10, 12]]`) genuinely appears in the output -- nothing about the program's own meaning changed, only *how* it was computed changed, from a real runtime `affine.for` loop to a real compile-time fold. This is the dialect-conversion driver's own documented behavior (trying an operation's own `fold()` hook before a `ConversionPattern`), not a defect in `AddOpLowering`'s own code, which is exactly why the chapter re-ran the same program with `--canonicalize` first: to make that same real folding happen visibly and deliberately, rather than as a side effect discovered only by reading the output closely.

**4. `mlir/docs/Bufferization.md` is cited in this chapter as stating `BufferizableOpInterface` requires implementing `bufferizesToMemoryRead`/`bufferizesToMemoryWrite`. Why does the chapter claim this is genuinely *more* work than `ConvertMgToAffinePass` needed, rather than a shortcut this chapter avoided for no real reason?**

Worked answer: `ConvertMgToAffinePass`'s own patterns only ever have to reason about one operation at a time, locally -- "allocate a buffer for my own result, compute into it." `BufferizableOpInterface`, by the documentation's own real description, supports a genuine whole-function analysis that decides whether a tensor value can be bufferized *in place* (reusing an existing buffer) or needs a fresh allocation, which requires each op to correctly answer real questions about whether it reads or writes through each operand *in the context of the rest of the function*, not in isolation -- a real, harder problem this chapter's own narrower, always-allocate-fresh patterns never had to solve.

**5. The chapter erases `mg.print` rather than lowering it to anything. What real, concrete problem would lowering it to an actual print call have to solve that this chapter's own other three patterns do not?**

Worked answer: `ConstantOpLowering`, `AddOpLowering`, and `TransposeOpLowering` all stay entirely within MLIR's own IR -- every operation they emit (`memref.alloc`, `affine.for`, `arith.addf`) is itself genuinely runnable by the same JIT/native-compilation pipeline Chapter 1 already proved works. A real print call needs to reach outside that pipeline entirely, into an actual C runtime function (something like a real `printf`-based helper) that has to be linked in or declared as an external symbol -- real native-execution machinery (`mlir-cpu-runner-18`/`ExecutionEngine`, or a real compiled host harness) this book has not yet built, which is exactly why the chapter defers it to Part 5 rather than inventing a placeholder call to nothing.
