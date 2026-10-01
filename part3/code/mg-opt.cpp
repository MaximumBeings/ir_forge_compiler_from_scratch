#include "mg/MgDialect.h"

#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/IR/DialectRegistry.h"
#include "mlir/InitAllDialects.h"
#include "mlir/Tools/mlir-opt/MlirOptMain.h"
#include "mlir/Transforms/Passes.h"

int main(int argc, char **argv) {
  mlir::registerCanonicalizerPass();
  mlir::registerCSEPass();

  mlir::DialectRegistry registry;
  registry.insert<mlir::func::FuncDialect>();
  registry.insert<mg::MgDialect>();
  return mlir::asMainReturnCode(
      mlir::MlirOptMain(argc, argv, "Mountain Goat (mg) dialect driver\n", registry));
}
