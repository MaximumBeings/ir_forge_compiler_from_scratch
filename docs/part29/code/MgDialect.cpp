#include "mg/MgDialect.h"
#include "mg/MgOps.h"
#include "mg/DynamicShapes.h"

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
  auto inputType = llvm::dyn_cast<mlir::RankedTensorType>(getInput().getType());
  auto resultType = llvm::dyn_cast<mlir::RankedTensorType>(getResult().getType());
  if (!inputType || !resultType)
    return emitOpError("mg.transpose only supports ranked tensors");
  if (inputType.getRank() != 2 || resultType.getRank() != 2)
    return emitOpError("mg.transpose only supports rank-2 tensors");
  auto inShape = inputType.getShape();
  auto outShape = resultType.getShape();
  if (!mg::dyn::compatibleDim(inShape[0], outShape[1]) ||
      !mg::dyn::compatibleDim(inShape[1], outShape[0]))
    return emitOpError("mg.transpose result shape must be the input shape reversed");
  return mlir::success();
}

mlir::LogicalResult AddOp::verify() {
  auto lhsType = llvm::dyn_cast<mlir::RankedTensorType>(getLhs().getType());
  auto rhsType = llvm::dyn_cast<mlir::RankedTensorType>(getRhs().getType());
  auto resType = llvm::dyn_cast<mlir::RankedTensorType>(getResult().getType());
  if (!lhsType || !rhsType || !resType)
    return emitOpError("mg.add only supports ranked tensors");
  if (lhsType.getRank() != rhsType.getRank() || lhsType.getRank() != resType.getRank())
    return emitOpError("mg.add operands and result must have the same rank");
  for (int64_t d = 0; d < lhsType.getRank(); ++d)
    if (!mg::dyn::compatibleDim(lhsType.getDimSize(d), rhsType.getDimSize(d)) ||
        !mg::dyn::compatibleDim(lhsType.getDimSize(d), resType.getDimSize(d)) ||
        !mg::dyn::compatibleDim(rhsType.getDimSize(d), resType.getDimSize(d)))
      return emitOpError("mg.add operands must have compatible shapes, got ")
             << lhsType << " and " << rhsType << " -> " << resType;
  return mlir::success();
}

namespace {
/// Shared by mg.add-style ops: same rank, every dimension compatible (equal, or `?` on either side).
mlir::LogicalResult verifyElementwise(mlir::Operation *op, llvm::ArrayRef<mlir::Type> types, llvm::StringRef name) {
  llvm::SmallVector<mlir::RankedTensorType, 3> t;
  for (mlir::Type ty : types) {
    auto r = llvm::dyn_cast<mlir::RankedTensorType>(ty);
    if (!r) return op->emitOpError(name + " only supports ranked tensors");
    t.push_back(r);
  }
  for (auto x : t)
    if (x.getRank() != t[0].getRank())
      return op->emitOpError(name + " operands and result must have the same rank");
  for (int64_t d = 0; d < t[0].getRank(); ++d)
    for (auto x : t)
      for (auto y : t)
        if (!mg::dyn::compatibleDim(x.getDimSize(d), y.getDimSize(d)))
          return op->emitOpError(name + " operands must have compatible shapes, got ") << x << " and " << y;
  return mlir::success();
}
} // namespace

mlir::LogicalResult SubOp::verify() { return verifyElementwise(*this, {getLhs().getType(), getRhs().getType(), getResult().getType()}, "mg.sub"); }
mlir::LogicalResult MulOp::verify() { return verifyElementwise(*this, {getLhs().getType(), getRhs().getType(), getResult().getType()}, "mg.mul"); }
mlir::LogicalResult DivOp::verify() { return verifyElementwise(*this, {getLhs().getType(), getRhs().getType(), getResult().getType()}, "mg.div"); }
mlir::LogicalResult ScalarOp::verify() {
  llvm::StringRef k = getOp();
  if (k != "add" && k != "sub" && k != "mul" && k != "div")
    return emitOpError("mg.scalar: op must be one of add, sub, mul, div, got '") << k << "'";
  return verifyElementwise(*this, {getInput().getType(), getResult().getType()}, "mg.scalar");
}
mlir::LogicalResult NegOp::verify() { return verifyElementwise(*this, {getInput().getType(), getResult().getType()}, "mg.neg"); }

namespace {
/// Chapter 28: reshape and permute work on static ranked tensors of any rank.
mlir::LogicalResult staticRanked(mlir::Operation *op, mlir::Type a, mlir::Type b, llvm::StringRef name,
                                 mlir::RankedTensorType &in, mlir::RankedTensorType &out) {
  in = llvm::dyn_cast<mlir::RankedTensorType>(a); out = llvm::dyn_cast<mlir::RankedTensorType>(b);
  if (!in || !out || !in.hasStaticShape() || !out.hasStaticShape())
    return op->emitOpError(name + " only supports static ranked tensors");
  return mlir::success();
}
} // namespace

mlir::LogicalResult ReshapeOp::verify() {
  mlir::RankedTensorType in, out;
  if (mlir::failed(staticRanked(*this, getInput().getType(), getResult().getType(), "mg.reshape", in, out))) return mlir::failure();
  if (in.getNumElements() != out.getNumElements())
    return emitOpError("mg.reshape: ") << in << " has " << in.getNumElements() << " elements but " << out << " has " << out.getNumElements();
  return mlir::success();
}

mlir::LogicalResult PermuteOp::verify() {
  mlir::RankedTensorType in, out;
  if (mlir::failed(staticRanked(*this, getInput().getType(), getResult().getType(), "mg.permute", in, out))) return mlir::failure();
  auto perm = getPermutation();
  if ((int64_t)perm.size() != in.getRank() || out.getRank() != in.getRank())
    return emitOpError("mg.permute: the permutation must list each of the ") << in.getRank() << " axes once";
  llvm::SmallVector<bool> seen(in.getRank(), false);
  for (int64_t p : perm) {
    if (p < 0 || p >= in.getRank() || seen[p]) return emitOpError("mg.permute: the permutation must list each axis exactly once");
    seen[p] = true;
  }
  for (int64_t i = 0; i < in.getRank(); ++i)
    if (out.getDimSize(i) != in.getDimSize(perm[i]))
      return emitOpError("mg.permute: result axis ") << i << " must have the size of input axis " << perm[i];
  return mlir::success();
}

mlir::LogicalResult ExpOp::verify() { return verifyElementwise(*this, {getInput().getType(), getResult().getType()}, "mg.exp"); }
mlir::LogicalResult ReluOp::verify() { return verifyElementwise(*this, {getInput().getType(), getResult().getType()}, "mg.relu"); }

mlir::LogicalResult ReduceOp::verify() {
  auto in = llvm::dyn_cast<mlir::RankedTensorType>(getInput().getType());
  auto out = llvm::dyn_cast<mlir::RankedTensorType>(getResult().getType());
  if (!in || !out || in.getRank() != 2 || out.getRank() != 2)
    return emitOpError("mg.reduce only supports rank-2 ranked tensors");
  if (getAxis() != 0 && getAxis() != 1)
    return emitOpError("mg.reduce: axis must be 0 or 1, got ") << getAxis();
  llvm::StringRef k = getKind();
  if (k != "sum" && k != "max")
    return emitOpError("mg.reduce: kind must be sum or max, got '") << k << "'";
  int64_t kept = 1 - getAxis();   // the dimension that survives
  if (!mg::dyn::compatibleDim(out.getDimSize(kept), in.getDimSize(kept)) || out.getDimSize(getAxis()) != 1)
    return emitOpError("mg.reduce: reducing axis ") << getAxis() << " of " << in << " must give a result with that axis of size 1, got " << out;
  return mlir::success();
}

mlir::LogicalResult BroadcastOp::verify() {
  auto in = llvm::dyn_cast<mlir::RankedTensorType>(getInput().getType());
  auto out = llvm::dyn_cast<mlir::RankedTensorType>(getResult().getType());
  if (!in || !out || in.getRank() != 2 || out.getRank() != 2)
    return emitOpError("mg.broadcast only supports rank-2 ranked tensors");
  if (!in.hasStaticShape() || !out.hasStaticShape())
    return emitOpError("mg.broadcast needs static shapes (dynamic broadcasting is not supported)");
  for (int d = 0; d < 2; ++d)
    if (in.getDimSize(d) != out.getDimSize(d) && in.getDimSize(d) != 1)
      return emitOpError("mg.broadcast: dimension ") << d << " of " << in << " can only grow from size 1, not to " << out;
  return mlir::success();
}

mlir::LogicalResult MatmulOp::verify() {
  auto l = llvm::dyn_cast<mlir::RankedTensorType>(getLhs().getType());
  auto r = llvm::dyn_cast<mlir::RankedTensorType>(getRhs().getType());
  auto o = llvm::dyn_cast<mlir::RankedTensorType>(getResult().getType());
  if (!l || !r || !o) return emitOpError("mg.matmul only supports ranked tensors");
  if (l.getRank() != 2 || r.getRank() != 2 || o.getRank() != 2)
    return emitOpError("mg.matmul only supports rank-2 tensors");
  if (!mg::dyn::compatibleDim(l.getDimSize(1), r.getDimSize(0)))
    return emitOpError("mg.matmul inner dimensions differ: ") << l << " times " << r;
  if (!mg::dyn::compatibleDim(o.getDimSize(0), l.getDimSize(0)) || !mg::dyn::compatibleDim(o.getDimSize(1), r.getDimSize(1)))
    return emitOpError("mg.matmul result shape must be (rows of lhs) x (columns of rhs), got ") << o;
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
    // With dynamic shapes the inner input's type can differ from this op's
    // result type (`tensor<?x2xf64>` vs `tensor<?x?xf64>`); replacing one
    // with the other would produce invalid IR, so only fire on an exact match.
    if (innerTranspose.getInput().getType() != op.getType())
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
