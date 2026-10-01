#include "mg/MgDialect.h"
#include "mg/MgOps.h"
#include "mg/DynamicShapes.h"

#include "mlir/Dialect/Affine/IR/AffineOps.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Bufferization/IR/BufferizableOpInterface.h"
#include "mlir/Dialect/Bufferization/IR/Bufferization.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/MemRef/IR/MemRef.h"
#include "mlir/IR/Dialect.h"

namespace {
/// The same real `printMemrefF64` mechanism Chapter 5 already established
/// -- reused here rather than reinvented, so this chapter's own
/// bufferization path can be run all the way to real execution too, not
/// just printed as IR text.
static mlir::FlatSymbolRefAttr
getOrInsertPrintMemrefF64(mlir::OpBuilder &builder, mlir::ModuleOp module) {
  const char *name = "printMemrefF64";
  if (module.lookupSymbol<mlir::func::FuncOp>(name))
    return mlir::SymbolRefAttr::get(builder.getContext(), name);

  auto unrankedMemrefF64 =
      mlir::UnrankedMemRefType::get(builder.getF64Type(), /*memorySpace=*/0);
  auto fnType = builder.getFunctionType({unrankedMemrefF64}, {});

  mlir::OpBuilder::InsertionGuard guard(builder);
  builder.setInsertionPointToStart(module.getBody());
  auto printFunc =
      builder.create<mlir::func::FuncOp>(module.getLoc(), name, fnType);
  printFunc.setPrivate();
  printFunc->setAttr("llvm.emit_c_interface", builder.getUnitAttr());
  return mlir::SymbolRefAttr::get(builder.getContext(), name);
}
} // namespace

using namespace mlir;
using namespace mlir::bufferization;

namespace {

/// `mg.constant` has no tensor operands at all -- it only ever *produces* a
/// tensor, from a `DenseElementsAttr` it already owns outright. Bufferizing
/// it is the simplest real case this file handles: allocate a real buffer,
/// write every element in, same as Chapter 4's own hand-written
/// `ConstantOpLowering`, just reached through a different real entry point.
struct ConstantOpInterface
    : public BufferizableOpInterface::ExternalModel<ConstantOpInterface,
                                                     mg::ConstantOp> {
  bool bufferizesToAllocation(Operation *op, Value value) const {
    return true;
  }

  LogicalResult bufferize(Operation *op, RewriterBase &rewriter,
                          const BufferizationOptions &options) const {
    auto constantOp = cast<mg::ConstantOp>(op);
    auto loc = op->getLoc();
    auto tensorType =
        cast<RankedTensorType>(constantOp.getResult().getType());
    auto memrefType =
        MemRefType::get(tensorType.getShape(), tensorType.getElementType());
    auto alloc = rewriter.create<memref::AllocOp>(loc, memrefType);

    llvm::SmallVector<double> values;
    for (auto v : constantOp.getValue().getValues<llvm::APFloat>())
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

    replaceOpWithBufferizedValues(rewriter, op, alloc.getResult());
    return success();
  }
};

/// `mg.add` genuinely reads both of its own operands' real buffers, but
/// never writes through them, and its own result never aliases either one
/// -- a fresh buffer is always allocated. Every one of these answers is a
/// real, specific claim One-Shot Bufferize's own whole-function analysis
/// depends on being correct, not a formality.
struct AddOpInterface
    : public BufferizableOpInterface::ExternalModel<AddOpInterface,
                                                     mg::AddOp> {
  bool bufferizesToMemoryRead(Operation *op, OpOperand &opOperand,
                              const AnalysisState &state) const {
    return true;
  }
  bool bufferizesToMemoryWrite(Operation *op, OpOperand &opOperand,
                               const AnalysisState &state) const {
    return false;
  }
  bool bufferizesToAllocation(Operation *op, Value value) const {
    return true;
  }
  AliasingValueList getAliasingValues(Operation *op, OpOperand &opOperand,
                                      const AnalysisState &state) const {
    return {};
  }

  LogicalResult bufferize(Operation *op, RewriterBase &rewriter,
                          const BufferizationOptions &options) const {
    auto addOp = cast<mg::AddOp>(op);
    auto loc = op->getLoc();

    FailureOr<Value> lhsBuffer = getBuffer(rewriter, addOp.getLhs(), options);
    if (failed(lhsBuffer))
      return failure();
    FailureOr<Value> rhsBuffer = getBuffer(rewriter, addOp.getRhs(), options);
    if (failed(rhsBuffer))
      return failure();

    auto tensorType = cast<RankedTensorType>(addOp.getResult().getType());
    auto memrefType =
        MemRefType::get(tensorType.getShape(), tensorType.getElementType());
    llvm::SmallVector<Value, 2> extents;
    for (int64_t d = 0; d < 2; ++d)
      extents.push_back(tensorType.isDynamicDim(d) ? mg::dyn::extentOf(rewriter, loc, *lhsBuffer, d) : Value());
    auto alloc = mg::dyn::allocFor(rewriter, loc, memrefType, extents);

    mg::dyn::nest2D(
        rewriter, loc, tensorType, extents,
        [&](OpBuilder &nestedBuilder, Location nestedLoc, ValueRange ivs) {
          Value lhsVal = nestedBuilder.create<affine::AffineLoadOp>(
              nestedLoc, *lhsBuffer, ivs);
          Value rhsVal = nestedBuilder.create<affine::AffineLoadOp>(
              nestedLoc, *rhsBuffer, ivs);
          Value sum =
              nestedBuilder.create<arith::AddFOp>(nestedLoc, lhsVal, rhsVal);
          nestedBuilder.create<affine::AffineStoreOp>(nestedLoc, sum, alloc,
                                                      ivs);
        });

    replaceOpWithBufferizedValues(rewriter, op, alloc.getResult());
    return success();
  }
};

/// `mg.transpose` is the same real shape as `mg.add`, with one operand
/// instead of two and an index swap between load and store instead of an
/// `arith.addf`.
struct TransposeOpInterface
    : public BufferizableOpInterface::ExternalModel<TransposeOpInterface,
                                                     mg::TransposeOp> {
  bool bufferizesToMemoryRead(Operation *op, OpOperand &opOperand,
                              const AnalysisState &state) const {
    return true;
  }
  bool bufferizesToMemoryWrite(Operation *op, OpOperand &opOperand,
                               const AnalysisState &state) const {
    return false;
  }
  bool bufferizesToAllocation(Operation *op, Value value) const {
    return true;
  }
  AliasingValueList getAliasingValues(Operation *op, OpOperand &opOperand,
                                      const AnalysisState &state) const {
    return {};
  }

  LogicalResult bufferize(Operation *op, RewriterBase &rewriter,
                          const BufferizationOptions &options) const {
    auto transposeOp = cast<mg::TransposeOp>(op);
    auto loc = op->getLoc();

    FailureOr<Value> inputBuffer =
        getBuffer(rewriter, transposeOp.getInput(), options);
    if (failed(inputBuffer))
      return failure();

    auto tensorType =
        cast<RankedTensorType>(transposeOp.getResult().getType());
    auto memrefType =
        MemRefType::get(tensorType.getShape(), tensorType.getElementType());
    llvm::SmallVector<Value, 2> extents;
    for (int64_t d = 0; d < 2; ++d)
      extents.push_back(tensorType.isDynamicDim(d) ? mg::dyn::extentOf(rewriter, loc, *inputBuffer, 1 - d) : Value());
    auto alloc = mg::dyn::allocFor(rewriter, loc, memrefType, extents);

    mg::dyn::nest2D(
        rewriter, loc, tensorType, extents,
        [&](OpBuilder &nestedBuilder, Location nestedLoc, ValueRange ivs) {
          Value i = ivs[0];
          Value j = ivs[1];
          Value loaded = nestedBuilder.create<affine::AffineLoadOp>(
              nestedLoc, *inputBuffer, ValueRange{j, i});
          nestedBuilder.create<affine::AffineStoreOp>(nestedLoc, loaded,
                                                      alloc, ValueRange{i, j});
        });

    replaceOpWithBufferizedValues(rewriter, op, alloc.getResult());
    return success();
  }
};

/// `mg.print` reads its own one operand's real buffer and produces no
/// result at all. Rather than erase it the way Chapter 4's own
/// hand-written pass did, this chapter reuses Chapter 5's own real
/// `printMemrefF64` mechanism directly, so this entirely different real
/// bufferization path can be run all the way to genuine execution too.
struct PrintOpInterface
    : public BufferizableOpInterface::ExternalModel<PrintOpInterface,
                                                     mg::PrintOp> {
  bool bufferizesToMemoryRead(Operation *op, OpOperand &opOperand,
                              const AnalysisState &state) const {
    return true;
  }
  bool bufferizesToMemoryWrite(Operation *op, OpOperand &opOperand,
                               const AnalysisState &state) const {
    return false;
  }
  AliasingValueList getAliasingValues(Operation *op, OpOperand &opOperand,
                                      const AnalysisState &state) const {
    return {};
  }

  LogicalResult bufferize(Operation *op, RewriterBase &rewriter,
                          const BufferizationOptions &options) const {
    auto printOp = cast<mg::PrintOp>(op);
    auto loc = op->getLoc();
    FailureOr<Value> inputBuffer =
        getBuffer(rewriter, printOp.getInput(), options);
    if (failed(inputBuffer))
      return failure();

    auto module = op->getParentOfType<ModuleOp>();
    auto printRef = getOrInsertPrintMemrefF64(rewriter, module);
    auto memrefType = cast<MemRefType>(inputBuffer->getType());
    auto unrankedType =
        UnrankedMemRefType::get(memrefType.getElementType(), /*memorySpace=*/0);
    Value cast =
        rewriter.create<memref::CastOp>(loc, unrankedType, *inputBuffer);
    rewriter.create<func::CallOp>(loc, printRef, TypeRange{}, ValueRange{cast});
    rewriter.eraseOp(op);
    return success();
  }
};

} // namespace

namespace mg {
void registerBufferizableOpInterfaceExternalModels(DialectRegistry &registry) {
  registry.addExtension(+[](MLIRContext *ctx, MgDialect *dialect) {
    ConstantOp::attachInterface<ConstantOpInterface>(*ctx);
    AddOp::attachInterface<AddOpInterface>(*ctx);
    TransposeOp::attachInterface<TransposeOpInterface>(*ctx);
    PrintOp::attachInterface<PrintOpInterface>(*ctx);
  });
}
} // namespace mg
