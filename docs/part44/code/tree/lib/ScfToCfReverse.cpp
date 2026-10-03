// --mg-scf-to-cf-reverse: lower scf.for / scf.if / scf.while to control flow like MLIR's --convert-scf-to-cf, but one top-level statement at a time, LAST TO FIRST.
//
// Why (Chapter 39): lowering a loop splits the block at the loop and moves every operation after it into a new block, so n loops in one block move about n^2/2 operations in all
// when they are lowered first to last. Lowered last to first, the tail after loop k has already been turned into a few branches, so each split moves only the few operations between
// two neighbouring loops. Chapter 42 measures whether that is enough. The result is the same control flow, in a different order of creation.
#include "mlir/Conversion/SCFToControlFlow/SCFToControlFlow.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/ControlFlow/IR/ControlFlowOps.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/SCF/IR/SCF.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Pass/PassRegistry.h"
#include "mlir/Transforms/DialectConversion.h"

using namespace mlir;

namespace {
struct ScfToCfReversePass : public PassWrapper<ScfToCfReversePass, OperationPass<func::FuncOp>> {
  MLIR_DEFINE_EXPLICIT_INTERNAL_INLINE_TYPE_ID(ScfToCfReversePass)
  StringRef getArgument() const final { return "mg-scf-to-cf-reverse"; }
  StringRef getDescription() const final { return "Lower scf to cf one top-level statement at a time, from the last to the first"; }
  void getDependentDialects(DialectRegistry &registry) const override { registry.insert<cf::ControlFlowDialect, arith::ArithDialect>(); }
  void runOnOperation() override {
    func::FuncOp func = getOperation();
    if (func.getBody().empty()) return;
    MLIRContext *ctx = &getContext();
    RewritePatternSet patterns(ctx);
    populateSCFToControlFlowConversionPatterns(patterns);
    FrozenRewritePatternSet frozen(std::move(patterns));
    ConversionTarget target(*ctx);
    target.addIllegalOp<scf::ForOp, scf::IfOp, scf::WhileOp, scf::ExecuteRegionOp, scf::IndexSwitchOp>();
    target.markUnknownOpDynamicallyLegal([](Operation *) { return true; });
    // Only the top-level statements of the entry block are handled one by one; they hold everything nested inside them. Collect them first, then go backwards.
    SmallVector<Operation *> tops;
    for (Operation &op : func.getBody().front())
      if (isa<scf::ForOp, scf::IfOp, scf::WhileOp, scf::ExecuteRegionOp, scf::IndexSwitchOp>(&op)) tops.push_back(&op);
    for (auto it = tops.rbegin(); it != tops.rend(); ++it) {
      Operation *one[] = {*it};
      if (failed(applyPartialConversion(ArrayRef<Operation *>(one), target, frozen))) { signalPassFailure(); return; }
    }
  }
};
}  // namespace

namespace mg {
void registerScfToCfReversePass() { PassRegistration<ScfToCfReversePass>(); }
}
