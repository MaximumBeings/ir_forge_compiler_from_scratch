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
#include "mlir/Dialect/MemRef/IR/MemRef.h"
#include "mlir/IR/DialectRegistry.h"
#include "mlir/InitAllDialects.h"
#include "mlir/Tools/mlir-opt/MlirOptMain.h"
#include "mlir/Transforms/Passes.h"

namespace mg {
void registerConvertMgToAffinePass();
void registerAssertToStderrPass();
void registerBufferizableOpInterfaceExternalModels(mlir::DialectRegistry &registry);
}

int main(int argc, char **argv) {
  mlir::registerCanonicalizerPass();
  mlir::registerCSEPass();
  mlir::registerReconcileUnrealizedCastsPass();
  mg::registerConvertMgToAffinePass();
  mg::registerAssertToStderrPass();
  mlir::bufferization::registerBufferizationPasses();
  mlir::registerConversionPasses();
  mlir::affine::registerAffinePasses();

  mlir::DialectRegistry registry;
  registry.insert<mlir::func::FuncDialect, mlir::affine::AffineDialect,
                  mlir::memref::MemRefDialect, mlir::arith::ArithDialect,
                  mlir::bufferization::BufferizationDialect,
                  mlir::cf::ControlFlowDialect, mlir::LLVM::LLVMDialect>();
  registry.insert<mg::MgDialect>();
  mg::registerBufferizableOpInterfaceExternalModels(registry);
  mlir::bufferization::func_ext::registerBufferizableOpInterfaceExternalModels(
      registry);
  return mlir::asMainReturnCode(
      mlir::MlirOptMain(argc, argv, "Mountain Goat (mg) dialect driver\n", registry));
}
