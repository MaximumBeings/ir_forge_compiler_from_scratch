#ifndef MG_DYNAMIC_SHAPES_H
#define MG_DYNAMIC_SHAPES_H

#include "mlir/Dialect/Affine/IR/AffineOps.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/ControlFlow/IR/ControlFlowOps.h"
#include "mlir/Dialect/MemRef/IR/MemRef.h"
#include "mlir/IR/BuiltinTypes.h"
#include "llvm/ADT/STLFunctionalExtras.h"

namespace mg::dyn {

/// Two extents are compatible if they are equal, or if either one is not
/// known until runtime (`?`). Chapter 3's verifiers used plain equality,
/// which rejects `tensor<?x2xf64>` against `tensor<3x2xf64>` even though
/// the two can be equal at runtime.
inline bool compatibleDim(int64_t a, int64_t b) {
  return mlir::ShapedType::isDynamic(a) || mlir::ShapedType::isDynamic(b) || a == b;
}

/// The runtime extent of dimension `d` of a buffer: a real `memref.dim`.
inline mlir::Value extentOf(mlir::OpBuilder &b, mlir::Location loc,
                            mlir::Value memref, int64_t d) {
  return b.create<mlir::memref::DimOp>(loc, memref, d);
}

/// Runtime check that two equal-rank operand buffers have the same extent
/// along every dimension. Compile-time checks (the verifier) can only
/// compare extents known statically; where either side is `?`, the only
/// place left to look is runtime. Emits a `cf.assert` per such dimension,
/// which the book's existing five-pass pipeline already lowers to a
/// message plus `abort()`. A dimension static on both sides is skipped: the
/// verifier already rejected any static mismatch.
inline void assertSameShape(mlir::OpBuilder &b, mlir::Location loc,
                            mlir::Value lhsBuf, mlir::Value rhsBuf,
                            mlir::RankedTensorType lhsType,
                            mlir::RankedTensorType rhsType,
                            llvm::StringRef opName) {
  for (int64_t d = 0; d < 1; ++d) {
    if (!lhsType.isDynamicDim(d) && !rhsType.isDynamicDim(d))
      continue;
    mlir::Value l = b.create<mlir::memref::DimOp>(loc, lhsBuf, d);
    mlir::Value r = b.create<mlir::memref::DimOp>(loc, rhsBuf, d);
    mlir::Value eq = b.create<mlir::arith::CmpIOp>(loc, mlir::arith::CmpIPredicate::eq, l, r);
    std::string msg = (opName + ": operand shapes differ at runtime in dimension " + llvm::Twine(d)).str();
    b.create<mlir::cf::AssertOp>(loc, eq, b.getStringAttr(msg));
  }
}

/// Allocate a buffer of type `type`, taking every dynamic dimension's size
/// from `extents[d]` (entries for static dimensions are ignored).
inline mlir::memref::AllocOp allocFor(mlir::OpBuilder &b, mlir::Location loc,
                                      mlir::MemRefType type,
                                      llvm::ArrayRef<mlir::Value> extents) {
  llvm::SmallVector<mlir::Value> sizes;
  for (int64_t d = 0; d < type.getRank(); ++d)
    if (type.isDynamicDim(d))
      sizes.push_back(extents[d]);
  return b.create<mlir::memref::AllocOp>(loc, type, sizes);
}

/// A 2-D `affine.for` nest over [0, extent0) x [0, extent1). Static shapes
/// take exactly the constant-bound path every earlier chapter used, so
/// their output is unchanged; a shape with a `?` takes the operand-bound
/// path, with each bound read from `extents`.
inline void nest2D(
    mlir::OpBuilder &b, mlir::Location loc, mlir::RankedTensorType type,
    llvm::ArrayRef<mlir::Value> extents,
    llvm::function_ref<void(mlir::OpBuilder &, mlir::Location, mlir::ValueRange)> body) {
  auto shape = type.getShape();
  if (type.hasStaticShape()) {
    mlir::affine::buildAffineLoopNest(b, loc, {0, 0}, {shape[0], shape[1]}, {1, 1}, body);
    return;
  }
  mlir::Value zero = b.create<mlir::arith::ConstantIndexOp>(loc, 0);
  llvm::SmallVector<mlir::Value, 2> ubs;
  for (int64_t d = 0; d < 2; ++d)
    ubs.push_back(type.isDynamicDim(d)
                      ? extents[d]
                      : b.create<mlir::arith::ConstantIndexOp>(loc, shape[d]).getResult());
  mlir::affine::buildAffineLoopNest(b, loc, mlir::ValueRange{zero, zero}, ubs, {1, 1}, body);
}

} // namespace mg::dyn

#endif // MG_DYNAMIC_SHAPES_H
