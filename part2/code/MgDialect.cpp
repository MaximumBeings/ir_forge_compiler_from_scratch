#include "mg/MgDialect.h"
#include "mg/MgOps.h"

#include "mlir/IR/Builders.h"
#include "mlir/IR/OpImplementation.h"

using namespace mg;

#include "mg/MgOpsDialect.cpp.inc"

void MgDialect::initialize() {
  addOperations<
#define GET_OP_LIST
#include "mg/MgOps.cpp.inc"
      >();
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
