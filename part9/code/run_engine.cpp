#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/LLVMIR/LLVMDialect.h"
#include "mlir/ExecutionEngine/CRunnerUtils.h"
#include "mlir/ExecutionEngine/ExecutionEngine.h"
#include "mlir/ExecutionEngine/OptUtils.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/MLIRContext.h"
#include "mlir/Parser/Parser.h"
#include "mlir/Target/LLVMIR/Dialect/Builtin/BuiltinToLLVMIRTranslation.h"
#include "mlir/Target/LLVMIR/Dialect/LLVMIR/LLVMToLLVMIRTranslation.h"

#include "llvm/Support/TargetSelect.h"

#include <iostream>

int main(int argc, char **argv) {
  if (argc != 2) {
    std::cerr << "usage: run_engine <llvm-dialect.mlir>\n";
    return 1;
  }

  llvm::InitializeNativeTarget();
  llvm::InitializeNativeTargetAsmPrinter();

  mlir::DialectRegistry registry;
  registry.insert<mlir::LLVM::LLVMDialect, mlir::func::FuncDialect>();
  mlir::registerLLVMDialectTranslation(registry);
  mlir::registerBuiltinDialectTranslation(registry);

  mlir::MLIRContext context(registry);
  context.loadAllAvailableDialects();

  mlir::OwningOpRef<mlir::ModuleOp> module =
      mlir::parseSourceFile<mlir::ModuleOp>(argv[1], &context);
  if (!module) {
    std::cerr << "failed to parse " << argv[1] << "\n";
    return 1;
  }

  mlir::ExecutionEngineOptions options;
  auto maybeEngine = mlir::ExecutionEngine::create(module.get(), options);
  if (!maybeEngine) {
    llvm::errs() << "failed to construct an execution engine: "
                 << maybeEngine.takeError() << "\n";
    return 1;
  }
  std::unique_ptr<mlir::ExecutionEngine> engine = std::move(*maybeEngine);

  double lhsData[4] = {1.0, 2.0, 3.0, 4.0};
  double rhsData[4] = {5.0, 6.0, 7.0, 8.0};
  double resultData[4] = {0.0, 0.0, 0.0, 0.0};

  StridedMemRefType<double, 2> lhs{
      lhsData, lhsData, 0, {2, 2}, {2, 1}};
  StridedMemRefType<double, 2> rhs{
      rhsData, rhsData, 0, {2, 2}, {2, 1}};
  StridedMemRefType<double, 2> result{
      resultData, resultData, 0, {2, 2}, {2, 1}};

  StridedMemRefType<double, 2> *resultPtr = &result;
  llvm::Error error = engine->invoke("add_tensors",
                                     mlir::ExecutionEngine::result(resultPtr),
                                     &lhs, &rhs);
  if (error) {
    llvm::errs() << "JIT invocation failed: " << error << "\n";
    return 1;
  }

  std::cout << "add_tensors([[1,2],[3,4]], [[5,6],[7,8]]) =\n";
  for (int64_t i = 0; i < 2; ++i) {
    for (int64_t j = 0; j < 2; ++j)
      std::cout << result.data[i * result.strides[0] + j * result.strides[1]]
                 << " ";
    std::cout << "\n";
  }
  return 0;
}
