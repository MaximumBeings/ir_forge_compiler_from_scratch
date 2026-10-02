// A replacement lowering for cf.assert that reports the message on STDERR before aborting.
//
// MLIR's own cf.assert lowering calls puts() (stdout) then abort(); abort() does not flush stdio buffers, so when stdout is
// a pipe or a file the message is lost (Chapter 14). This pass rewrites each cf.assert, BEFORE the normal lowering would see it, into
//     cf.cond_br %cond, ^continue, ^fail
//   ^fail:  llvm.call @write(2, "message\n", len) ; llvm.call @abort() ; llvm.unreachable
// write(2, ...) is a direct system call wrapper: unbuffered, no FILE*, so nothing is left unflushed when abort() runs.
#include "mlir/Dialect/ControlFlow/IR/ControlFlowOps.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/LLVMIR/LLVMDialect.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Transforms/GreedyPatternRewriteDriver.h"
#include "llvm/ADT/StringExtras.h"

using namespace mlir;

namespace {
/// Finds or creates a module-level llvm.func declaration.
static LLVM::LLVMFuncOp getOrDeclare(ModuleOp module, StringRef name, Type result, ArrayRef<Type> args) {
  if (auto f = module.lookupSymbol<LLVM::LLVMFuncOp>(name))
    return f;
  OpBuilder b(module.getBodyRegion());
  return b.create<LLVM::LLVMFuncOp>(module.getLoc(), name, LLVM::LLVMFunctionType::get(result, args));
}

struct AssertToStderrPattern : public OpRewritePattern<cf::AssertOp> {
  using OpRewritePattern::OpRewritePattern;

  LogicalResult matchAndRewrite(cf::AssertOp op, PatternRewriter &rewriter) const override {
    // Only rewrite asserts that sit directly in a function body, where several blocks are legal. An assert nested inside a
    // region that requires a single block (an affine.for or scf.for body, for example) cannot be split into blocks without
    // producing invalid IR, so it is left for MLIR's default lowering. Running this pass AFTER --convert-scf-to-cf, when no
    // structured control flow is left, makes every assert eligible.
    auto module = op->getParentOfType<ModuleOp>();
    Location loc = op.getLoc();
    MLIRContext *ctx = rewriter.getContext();
    Type i8 = rewriter.getI8Type(), i32 = rewriter.getI32Type(), i64 = rewriter.getI64Type();
    Type ptr = LLVM::LLVMPointerType::get(ctx);

    // One private constant string global per assert: the message plus a newline.
    std::string text = op.getMsg().str() + "\n";
    // Pick a global name no existing symbol uses, so the pass can run more than once on a module (a first run leaves a nested assert,
    // a second run after --convert-scf-to-cf rewrites it) without "redefinition of symbol" errors.
    std::string name;
    for (unsigned k = 0;; ++k) {
      name = "mg_assert_stderr_msg_" + std::to_string(k);
      if (!module.lookupSymbol(name))
        break;
    }
    {
      OpBuilder::InsertionGuard g(rewriter);
      rewriter.setInsertionPointToStart(module.getBody());
      rewriter.create<LLVM::GlobalOp>(loc, LLVM::LLVMArrayType::get(i8, text.size()), /*isConstant=*/true,
                                      LLVM::Linkage::Private, name, rewriter.getStringAttr(text));
    }
    LLVM::LLVMFuncOp writeFn = getOrDeclare(module, "write", i64, {i32, ptr, i64});
    LLVM::LLVMFuncOp abortFn = getOrDeclare(module, "abort", LLVM::LLVMVoidType::get(ctx), {});

    // Split the block at the assert: everything after it moves to ^continue.
    Block *here = op->getBlock();
    Block *cont = rewriter.splitBlock(here, Block::iterator(op));
    Block *fail = rewriter.createBlock(cont);   // placed between `here` and `cont`

    rewriter.setInsertionPointToEnd(fail);
    Value fd = rewriter.create<LLVM::ConstantOp>(loc, i32, rewriter.getI32IntegerAttr(2));
    Value len = rewriter.create<LLVM::ConstantOp>(loc, i64, rewriter.getI64IntegerAttr(text.size()));
    Value msg = rewriter.create<LLVM::AddressOfOp>(loc, ptr, name);
    rewriter.create<LLVM::CallOp>(loc, writeFn, ValueRange{fd, msg, len});
    rewriter.create<LLVM::CallOp>(loc, abortFn, ValueRange{});
    rewriter.create<LLVM::UnreachableOp>(loc);

    rewriter.setInsertionPointToEnd(here);
    rewriter.create<cf::CondBranchOp>(loc, op.getArg(), cont, ValueRange{}, fail, ValueRange{});
    rewriter.eraseOp(op);
    return success();
  }
};

struct MgAssertToStderrPass : public PassWrapper<MgAssertToStderrPass, OperationPass<ModuleOp>> {
  MLIR_DEFINE_EXPLICIT_INTERNAL_INLINE_TYPE_ID(MgAssertToStderrPass)
  StringRef getArgument() const final { return "mg-lower-assert-to-stderr"; }
  StringRef getDescription() const final {
    return "Rewrite cf.assert into a branch that write()s its message to fd 2 and aborts (MLIR's own lowering uses buffered stdout)";
  }
  void getDependentDialects(DialectRegistry &registry) const override {
    registry.insert<cf::ControlFlowDialect, LLVM::LLVMDialect>();
  }
  void runOnOperation() override {
    RewritePatternSet patterns(&getContext());
    patterns.add<AssertToStderrPattern>(&getContext());
    if (failed(applyPatternsAndFoldGreedily(getOperation(), std::move(patterns))))
      signalPassFailure();
  }
};
} // namespace

namespace mg {
void registerAssertToStderrPass() { PassRegistration<MgAssertToStderrPass>(); }
} // namespace mg
