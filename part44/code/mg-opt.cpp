#include "mg/MgDialect.h"

#include "mlir/Conversion/Passes.h"
#include "mlir/Dialect/Affine/IR/AffineOps.h"
#include "mlir/Dialect/Affine/Passes.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Bufferization/IR/Bufferization.h"
#include "mlir/Dialect/ControlFlow/IR/ControlFlowOps.h"
#include "mlir/Dialect/Bufferization/Transforms/FuncBufferizableOpInterfaceImpl.h"
#include "mlir/Dialect/Bufferization/Transforms/Passes.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/LLVMIR/LLVMDialect.h"
#include "mlir/Dialect/Math/IR/Math.h"
#include "mlir/Dialect/SCF/IR/SCF.h"
#include "mlir/Dialect/MemRef/IR/MemRef.h"
#include "mlir/Dialect/Tensor/IR/Tensor.h"
#include "mlir/IR/DialectRegistry.h"
#include "mlir/InitAllDialects.h"
#include "mlir/Tools/mlir-opt/MlirOptMain.h"
#include "mlir/Transforms/Passes.h"

namespace mg {
void registerConvertMgToAffinePass();
void registerAssertToStderrPass();
void registerOutlineLoopsPass();
void registerScfToCfReversePass();
void registerSetFastMathPass();
void registerBufferizableOpInterfaceExternalModels(mlir::DialectRegistry &registry);
}

int main(int argc, char **argv) {
  mlir::registerCanonicalizerPass();
  mlir::registerCSEPass();
  mlir::registerReconcileUnrealizedCastsPass();
  mg::registerConvertMgToAffinePass();
  mg::registerAssertToStderrPass();
  mg::registerOutlineLoopsPass();
  mg::registerScfToCfReversePass();
  mg::registerSetFastMathPass();
  mlir::bufferization::registerBufferizationPasses();
  mlir::registerConversionPasses();
  mlir::affine::registerAffinePasses();

  mlir::DialectRegistry registry;
  registry.insert<mlir::func::FuncDialect, mlir::affine::AffineDialect,
                  mlir::memref::MemRefDialect, mlir::arith::ArithDialect,
                  mlir::bufferization::BufferizationDialect,
                  mlir::cf::ControlFlowDialect, mlir::LLVM::LLVMDialect,
                  mlir::tensor::TensorDialect, mlir::math::MathDialect, mlir::scf::SCFDialect>();    // scf: Chapter 42 reads scf text directly
  registry.insert<mg::MgDialect>();
  mg::registerBufferizableOpInterfaceExternalModels(registry);
  mlir::bufferization::func_ext::registerBufferizableOpInterfaceExternalModels(
      registry);
  return mlir::asMainReturnCode(
      mlir::MlirOptMain(argc, argv, "Mountain Goat (mg) dialect driver\n", registry));
}
