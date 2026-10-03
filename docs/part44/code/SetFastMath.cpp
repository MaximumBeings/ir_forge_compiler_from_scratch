// --mg-set-fastmath{flags=reassoc,contract}: put LLVM fast-math flags on the floating-point arith operations of the program.
//
// Why (Chapter 37): LLVM's vectorizer refuses to vectorize a floating-point sum (the inner loop of a dot product) because adding the terms in another order can change the rounding, and
// the program did not say that is allowed. The `reassoc` flag says it is; `contract` allows a multiply and an add to become one fused multiply-add. Both are flags on the individual
// instructions, so they can be given where the compiler knows the program tolerates them, without `-ffast-math` (which turns on more, including assumptions about NaN and infinity that
// Mountain Goat's softmax relies on NOT being made). The flags given are a pass option; the default is reassoc and contract only.
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Pass/PassRegistry.h"
#include "llvm/ADT/StringSwitch.h"

using namespace mlir;

namespace {
struct SetFastMathPass : public PassWrapper<SetFastMathPass, OperationPass<ModuleOp>> {
  MLIR_DEFINE_EXPLICIT_INTERNAL_INLINE_TYPE_ID(SetFastMathPass)
  SetFastMathPass() = default;
  SetFastMathPass(const SetFastMathPass &other) : PassWrapper(other) {}      // an Option is not copyable (Chapter 38)
  Option<std::string> flags{*this, "flags", llvm::cl::desc("comma-separated fast-math flags: reassoc, contract, nnan, ninf, nsz, arcp, afn"), llvm::cl::init("reassoc,contract")};
  StringRef getArgument() const final { return "mg-set-fastmath"; }
  StringRef getDescription() const final { return "Set fast-math flags (default reassoc,contract) on floating-point arith operations"; }
  void getDependentDialects(DialectRegistry &registry) const override { registry.insert<arith::ArithDialect>(); }
  void runOnOperation() override {
    arith::FastMathFlags fm = arith::FastMathFlags::none;
    SmallVector<StringRef> parts; StringRef(flags).split(parts, ',', -1, false);
    for (StringRef p : parts) {
      auto parsed = arith::symbolizeFastMathFlags(p.trim());
      if (!parsed) { getOperation().emitError("unknown fast-math flag '" + p.str() + "'"); return signalPassFailure(); }
      fm = fm | *parsed;
    }
    MLIRContext *ctx = &getContext(); auto attr = arith::FastMathFlagsAttr::get(ctx, fm); unsigned count = 0;
    getOperation().walk([&](Operation *op) {
      if (auto iface = dyn_cast<arith::ArithFastMathInterface>(op)) { op->setAttr(iface.getFastMathAttrName(), attr); ++count; }
    });
    numChanged = count;
  }
  unsigned numChanged = 0;
};
}  // namespace

namespace mg {
void registerSetFastMathPass() { PassRegistration<SetFastMathPass>(); }
}
