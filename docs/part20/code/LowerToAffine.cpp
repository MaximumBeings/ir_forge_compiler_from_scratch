#include "mg/MgDialect.h"
#include "mg/MgOps.h"
#include "mg/DynamicShapes.h"

#include "mlir/Dialect/Affine/IR/AffineOps.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/Func/Transforms/FuncConversions.h"
#include "mlir/Dialect/MemRef/IR/MemRef.h"
#include "mlir/Dialect/Tensor/IR/Tensor.h"
#include "mlir/IR/BuiltinTypes.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Transforms/DialectConversion.h"

using namespace mlir;

namespace {

/// Mountain Goat's own real tensor-to-memref type conversion: a
/// `tensor<NxMxf64>` becomes a `memref<NxMxf64>`, same shape, same element
/// type -- deliberately only the shape this chapter's own worked examples
/// need (static, rank 2), not a general bufferization scheme.
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

/// mg.constant lowers to a real `memref.alloc` plus a fully-unrolled
/// sequence of real `affine.store`s, one per element -- genuinely correct
/// only because this chapter's own worked examples use small, static
/// shapes; a general lowering would emit a real loop nest here instead.
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

/// mg.add lowers to a real `affine.for` loop nest, one real `affine.load`
/// from each operand, a real `arith.addf`, and a real `affine.store` into
/// a freshly allocated result buffer -- the real, concrete thing MLIR's
/// own rationale (Chapter 1) means by "progressive lowering."
struct AddOpLowering : public OpConversionPattern<mg::AddOp> {
  using OpConversionPattern::OpConversionPattern;

  LogicalResult
  matchAndRewrite(mg::AddOp op, OpAdaptor adaptor,
                 ConversionPatternRewriter &rewriter) const override {
    auto loc = op.getLoc();
    auto tensorType = llvm::cast<RankedTensorType>(op.getResult().getType());
    auto memrefType = convertTensorToMemref(tensorType);

    Value lhs = adaptor.getLhs();
    Value rhs = adaptor.getRhs();
    mg::dyn::assertSameShape(rewriter, loc, lhs, rhs,
                             llvm::cast<RankedTensorType>(op.getLhs().getType()),
                             llvm::cast<RankedTensorType>(op.getRhs().getType()), "mg.add");
    llvm::SmallVector<Value, 2> extents;
    for (int64_t d = 0; d < 2; ++d)
      extents.push_back(tensorType.isDynamicDim(d) ? mg::dyn::extentOf(rewriter, loc, lhs, d) : Value());
    auto alloc = mg::dyn::allocFor(rewriter, loc, memrefType, extents);

    mg::dyn::nest2D(
        rewriter, loc, tensorType, extents,
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

/// mg.transpose lowers to a real `affine.for` loop nest over the *output*
/// shape, loading `input[j, i]` and storing to `result[i, j]` -- the
/// transpose is the real index swap between load and store, nothing more.
struct TransposeOpLowering : public OpConversionPattern<mg::TransposeOp> {
  using OpConversionPattern::OpConversionPattern;

  LogicalResult
  matchAndRewrite(mg::TransposeOp op, OpAdaptor adaptor,
                 ConversionPatternRewriter &rewriter) const override {
    auto loc = op.getLoc();
    auto tensorType = llvm::cast<RankedTensorType>(op.getResult().getType());
    auto memrefType = convertTensorToMemref(tensorType);

    Value input = adaptor.getInput();
    // The result's extent along d is the input's extent along 1 - d.
    llvm::SmallVector<Value, 2> extents;
    for (int64_t d = 0; d < 2; ++d)
      extents.push_back(tensorType.isDynamicDim(d) ? mg::dyn::extentOf(rewriter, loc, input, 1 - d) : Value());
    auto alloc = mg::dyn::allocFor(rewriter, loc, memrefType, extents);

    mg::dyn::nest2D(
        rewriter, loc, tensorType, extents,
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

/// Returns a real symbol reference to `@printMemrefF64`, inserting a real
/// `func.func private` declaration for it the first time it is needed.
/// `printMemrefF64` is not this chapter's own invention -- it is a real,
/// pre-existing function in MLIR's own `RunnerUtils.h`/
/// `libmlir_runner_utils.so`, the same real runtime support library the
/// official Toy tutorial's own later chapters rely on for exactly this
/// job. `llvm.emit_c_interface` is the one real attribute that makes
/// `--convert-func-to-llvm` emit a call to the real `_mlir_ciface_`-prefixed
/// C-interface wrapper that function's own real ABI expects, rather than
/// to a plain, mismatched symbol.
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

/// mg.print lowers to a real `memref.cast` to an unranked memref, plus a
/// real call to `@printMemrefF64` -- genuinely running, observable output,
/// rather than an op this chapter has no way to execute.
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

/// Chapter 20: tensor.cast, which the surface-syntax front end emits when a
/// statically shaped value is passed to a function taking tensor<?x?xf64>.
/// The bufferized form of a cast between tensor types is a memref.cast between
/// the converted memref types; it changes only the *type*, never the data.
struct TensorCastLowering : public OpConversionPattern<tensor::CastOp> {
  using OpConversionPattern::OpConversionPattern;

  LogicalResult
  matchAndRewrite(tensor::CastOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    Type resultType = getTypeConverter()->convertType(op.getType());
    if (!resultType)
      return failure();
    rewriter.replaceOpWithNewOp<memref::CastOp>(op, resultType,
                                                adaptor.getSource());
    return success();
  }
};

struct ConvertMgToAffinePass
    : public PassWrapper<ConvertMgToAffinePass, OperationPass<ModuleOp>> {
  MLIR_DEFINE_EXPLICIT_INTERNAL_INLINE_TYPE_ID(ConvertMgToAffinePass)

  llvm::StringRef getArgument() const final { return "convert-mg-to-affine"; }
  llvm::StringRef getDescription() const final {
    return "Lower Mountain Goat's own mg dialect to affine/memref/arith, "
           "hand-bufferizing each op's own result as it is lowered.";
  }

  void getDependentDialects(DialectRegistry &registry) const override {
    registry.insert<affine::AffineDialect, memref::MemRefDialect,
                    arith::ArithDialect, cf::ControlFlowDialect,
                    tensor::TensorDialect>();
  }

  void runOnOperation() override {
    MgToAffineTypeConverter typeConverter;
    ConversionTarget target(getContext());
    target.addLegalDialect<affine::AffineDialect, memref::MemRefDialect,
                           arith::ArithDialect, cf::ControlFlowDialect>();
    target.addIllegalDialect<mg::MgDialect>();
    target.addIllegalOp<tensor::CastOp>();

    // A real, genuine gap this chapter's own first attempt hit directly:
    // mg.add/mg.transpose's own *operations* are made illegal above, but a
    // function's own block arguments (e.g. `%a: tensor<2x2xf64>`) are never
    // touched by that -- func.func's own signature needs its own real
    // conversion, via MLIR's own built-in utility for exactly this.
    target.addDynamicallyLegalOp<func::FuncOp>([&](func::FuncOp op) {
      return typeConverter.isSignatureLegal(op.getFunctionType()) &&
             typeConverter.isLegal(&op.getBody());
    });
    target.addDynamicallyLegalOp<func::ReturnOp>([&](func::ReturnOp op) {
      return typeConverter.isLegal(op.getOperandTypes());
    });
    // A real second instance of the same real problem: `@main`'s own
    // `func.call @add_tensors(...)` passes tensor-typed operands too, and
    // needs its own real conversion pattern, via another real MLIR utility.
    target.addDynamicallyLegalOp<func::CallOp>([&](func::CallOp op) {
      return typeConverter.isLegal(op.getOperandTypes()) &&
             typeConverter.isLegal(op.getResultTypes());
    });

    RewritePatternSet patterns(&getContext());
    patterns.add<ConstantOpLowering, AddOpLowering, TransposeOpLowering,
                PrintOpLowering, TensorCastLowering>(typeConverter, &getContext());
    populateFunctionOpInterfaceTypeConversionPattern<func::FuncOp>(patterns,
                                                                   typeConverter);
    populateCallOpTypeConversionPattern(patterns, typeConverter);
    populateReturnOpTypeConversionPattern(patterns, typeConverter);

    if (failed(applyPartialConversion(getOperation(), target,
                                      std::move(patterns))))
      signalPassFailure();
  }
};

} // namespace

namespace mg {
void registerConvertMgToAffinePass() {
  PassRegistration<ConvertMgToAffinePass>();
}
} // namespace mg
