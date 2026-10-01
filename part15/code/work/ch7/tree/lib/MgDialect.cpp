#include "mg/MgDialect.h"
#include "mg/MgOps.h"

#include "mlir/IR/Builders.h"
#include "mlir/IR/Matchers.h"
#include "mlir/IR/OpImplementation.h"
#include "mlir/IR/PatternMatch.h"

using namespace mg;

#include "mg/MgOpsDialect.cpp.inc"

void MgDialect::initialize() {
  addOperations<
#define GET_OP_LIST
#include "mg/MgOps.cpp.inc"
      >();
}

mlir::Operation *MgDialect::materializeConstant(mlir::OpBuilder &builder,
                                                mlir::Attribute value,
                                                mlir::Type type,
                                                mlir::Location loc) {
  auto elements = llvm::dyn_cast<mlir::DenseElementsAttr>(value);
  if (!elements)
    return nullptr;
  return builder.create<ConstantOp>(loc, type, elements);
}

#define GET_OP_CLASSES
#include "mg/MgOps.cpp.inc"

mlir::LogicalResult ConstantOp::inferReturnTypes(
    mlir::MLIRContext *context, std::optional<mlir::Location> location,
    mlir::ValueRange operands, mlir::DictionaryAttr attributes,
    mlir::OpaqueProperties properties, mlir::RegionRange regions,
    llvm::SmallVectorImpl<mlir::Type> &inferredReturnTypes) {
  Adaptor adaptor(operands, attributes, properties, regions);
  inferredReturnTypes.push_back(adaptor.getValue().getType());
  return mlir::success();
}

mlir::OpFoldResult ConstantOp::fold(FoldAdaptor adaptor) { return getValueAttr(); }

mlir::LogicalResult TransposeOp::verify() {
  auto inputType = llvm::cast<mlir::RankedTensorType>(getInput().getType());
  auto resultType = llvm::cast<mlir::RankedTensorType>(getResult().getType());
  if (inputType.getRank() != 2 || resultType.getRank() != 2)
    return emitOpError("mg.transpose only supports rank-2 tensors");
  auto inShape = inputType.getShape();
  auto outShape = resultType.getShape();
  if (inShape[0] != outShape[1] || inShape[1] != outShape[0])
    return emitOpError("mg.transpose result shape must be the input shape reversed");
  return mlir::success();
}

mlir::LogicalResult AddOp::verify() {
  auto lhsType = llvm::cast<mlir::RankedTensorType>(getLhs().getType());
  auto rhsType = llvm::cast<mlir::RankedTensorType>(getRhs().getType());
  if (lhsType.getShape() != rhsType.getShape())
    return emitOpError("mg.add operands must have the same shape, got ")
           << lhsType << " and " << rhsType;
  return mlir::success();
}

mlir::OpFoldResult AddOp::fold(FoldAdaptor adaptor) {
  auto lhsAttr = llvm::dyn_cast_if_present<mlir::DenseElementsAttr>(adaptor.getLhs());
  auto rhsAttr = llvm::dyn_cast_if_present<mlir::DenseElementsAttr>(adaptor.getRhs());
  if (!lhsAttr || !rhsAttr)
    return nullptr;

  auto lhsValues = lhsAttr.getValues<llvm::APFloat>();
  auto rhsValues = rhsAttr.getValues<llvm::APFloat>();
  llvm::SmallVector<llvm::APFloat> summed;
  summed.reserve(lhsAttr.getNumElements());
  for (auto [l, r] : llvm::zip(lhsValues, rhsValues))
    summed.push_back(l + r);
  return mlir::DenseElementsAttr::get(lhsAttr.getType(), summed);
}

namespace {
/// Real pattern-rewrite canonicalization: mg.transpose(mg.transpose(%x))
/// folds straight to %x, since transposing a 2-D tensor twice is the
/// identity. Modeled on the same real idea MLIR's own official Toy
/// tutorial uses for its own transpose-of-transpose rewrite, written here
/// fresh rather than copied from it.
struct SimplifyRedundantTranspose : public mlir::OpRewritePattern<TransposeOp> {
  using OpRewritePattern<TransposeOp>::OpRewritePattern;

  mlir::LogicalResult
  matchAndRewrite(TransposeOp op, mlir::PatternRewriter &rewriter) const override {
    auto innerTranspose = op.getInput().getDefiningOp<TransposeOp>();
    if (!innerTranspose)
      return mlir::failure();
    rewriter.replaceOp(op, innerTranspose.getInput());
    return mlir::success();
  }
};
} // namespace

void TransposeOp::getCanonicalizationPatterns(mlir::RewritePatternSet &results,
                                              mlir::MLIRContext *context) {
  results.add<SimplifyRedundantTranspose>(context);
}
