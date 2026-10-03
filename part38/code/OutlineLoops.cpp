// --mg-outline-loops: move every top-level loop nest of a big function into a small shared function, and replace it with a call.
//
// Why (Chapter 38): MLIR's SCFToControlFlow takes time that grows roughly with the SQUARE of the number of loops in one function (measured: 16,000 loops in one function
// 18.9 s; the same loops in functions of 500: 0.17 s). The unrolled training programs of Chapters 35 and 36 put tens of thousands of loop nests, one per matrix operation,
// into `main`. This pass cuts `main` into pieces of one loop nest each, and then DEDUPLICATES the pieces: two nests that are the same loops over the same shapes become
// one function called twice. A program with 190,000 loop nests has only a few dozen distinct ones.
//
// What it does, per function with at least `min-loops` top-level affine.for ops:
//   1. for each top-level affine.for, find the values it uses that are defined outside it;
//   2. arith.constant values are CLONED into the new function (so the same nest over different constants does not look different); every other outside value
//      (a memref, an index or a float computed outside) becomes an ARGUMENT;
//   3. build `func.func private @mg_outlined_N(args) { clone of the nest; return }`, print it, and if an identical function (same text, ignoring the name) exists, use that
//      one and discard the new one;
//   4. replace the nest with a func.call.
// Loops nested inside other loops are untouched. The result computes exactly the same thing: the callee reads and writes the same memrefs.
#include "mlir/Dialect/Affine/IR/AffineOps.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/IRMapping.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Pass/PassRegistry.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/StringMap.h"

using namespace mlir;

namespace {
struct OutlineLoopsPass : public PassWrapper<OutlineLoopsPass, OperationPass<ModuleOp>> {
  MLIR_DEFINE_EXPLICIT_INTERNAL_INLINE_TYPE_ID(OutlineLoopsPass)
  OutlineLoopsPass() = default;
  OutlineLoopsPass(const OutlineLoopsPass &other) : PassWrapper(other) {}      // the pass framework copies passes; an Option is not copyable
  Option<int> minLoops{*this, "min-loops", llvm::cl::desc("only functions with at least this many top-level loop nests are outlined"), llvm::cl::init(32)};
  StringRef getArgument() const final { return "mg-outline-loops"; }
  StringRef getDescription() const final { return "Outline top-level affine loop nests into deduplicated functions (cuts compile time of huge functions)"; }
  void getDependentDialects(DialectRegistry &registry) const override { registry.insert<func::FuncDialect, affine::AffineDialect, arith::ArithDialect>(); }

  void runOnOperation() override {
    ModuleOp module = getOperation();
    MLIRContext *ctx = &getContext();
    llvm::StringMap<func::FuncOp> known;        // printed function text (with a fixed name) -> the function that has it
    unsigned counter = 0;
    SmallVector<func::FuncOp> funcs;
    for (auto f : module.getOps<func::FuncOp>())
      if (!f.isExternal()) funcs.push_back(f);
    for (func::FuncOp f : funcs) {
      SmallVector<affine::AffineForOp> nests;
      for (Operation &op : f.getBody().front())
        if (auto forOp = dyn_cast<affine::AffineForOp>(&op)) nests.push_back(forOp);
      if ((int)nests.size() < minLoops) continue;
      for (affine::AffineForOp forOp : nests) {
        auto definedOutside = [&](Value v) {
          Operation *owner = v.getDefiningOp() ? v.getDefiningOp() : v.getParentBlock()->getParentOp();
          return !forOp->isAncestor(owner);
        };
        llvm::SetVector<Value> args;
        SmallVector<arith::ConstantOp> consts;
        forOp.walk([&](Operation *op) {
          for (Value v : op->getOperands()) {
            if (!definedOutside(v)) continue;
            if (auto c = v.getDefiningOp<arith::ConstantOp>()) {
              if (!llvm::is_contained(consts, c)) consts.push_back(c);
            } else {
              args.insert(v);
            }
          }
        });
        SmallVector<Type> argTypes;
        for (Value v : args) argTypes.push_back(v.getType());
        Location loc = forOp.getLoc();
        func::FuncOp callee = func::FuncOp::create(loc, "mg_outlined_tmp", FunctionType::get(ctx, argTypes, {}));
        callee.setPrivate();
        Block *entry = callee.addEntryBlock();
        OpBuilder b = OpBuilder::atBlockBegin(entry);
        IRMapping map;
        for (auto [orig, arg] : llvm::zip(args, entry->getArguments())) map.map(orig, arg);
        for (arith::ConstantOp c : consts) b.clone(*c, map);
        b.clone(*forOp.getOperation(), map);
        b.create<func::ReturnOp>(loc);
        std::string key;
        llvm::raw_string_ostream os(key);
        callee.print(os);
        auto it = known.find(key);
        if (it != known.end()) {
          callee->destroy();
          callee = it->second;
        } else {
          callee.setName("mg_outlined_" + std::to_string(counter++));
          module.push_back(callee);
          known[key] = callee;
        }
        OpBuilder cb(forOp);
        cb.create<func::CallOp>(loc, callee, args.getArrayRef());
        forOp.erase();
      }
    }
  }
};
}  // namespace

namespace mg {
void registerOutlineLoopsPass() { PassRegistration<OutlineLoopsPass>(); }
}  // namespace mg
