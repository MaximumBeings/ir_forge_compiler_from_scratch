#!/bin/sh
# Four deliberate bugs in the new pass, each applied to a COPY of this chapter's source tree, rebuilt, and tested against the assert-stderr tests.
# Needs ./build.sh to have been run (it creates tree/). Each mutation rebuilds mg-opt, so this takes a few minutes. Output: stderr_mutation_out.txt
HERE=$(cd "$(dirname "$0")" && pwd); SRC=$HERE/tree; SUITE=$HERE/../../part15/code/test/assert-stderr
mutate() {  # name, description, python edit (receives the path to AssertToStderr.cpp). ONLY=n runs just mutation n.
  [ -z "$ONLY" ] || [ "$ONLY" = "$1" ] || return
  W=$HERE/work/sm-$1; rm -rf "$W"; mkdir -p "$W/build/include/mg"; cp -r "$SRC" "$W/tree"
  python3 -c "$3" "$W/tree/lib/AssertToStderr.cpp" || { echo "MUTATION $1 NOT APPLIED ($2)"; return; }
  (cd "$W/build" && cmake "$W/tree" -DMLIR_DIR=/usr/lib/llvm-18/lib/cmake/mlir -DLLVM_DIR=/usr/lib/llvm-18/lib/cmake/llvm \
     -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=OFF >/dev/null 2>&1 && make -j8 2>&1 | grep -E " error " || true)
  echo "MUTATION $1: $2"
  MG_OPT=$W/build/mg-opt MG_TEST_TMP=$W/out lit "$SUITE" 2>&1 | grep -E "^(PASS|FAIL)" | sed 's/IR Forge \/ Mountain Goat :: /   /;s/ ([0-9]* of [0-9]*)//' | sort
}
mutate 1 "message written to fd 1 (stdout) instead of fd 2 (stderr)" \
  'import sys; p=sys.argv[1]; s=open(p).read(); a="rewriter.getI32IntegerAttr(2)"; assert a in s; open(p,"w").write(s.replace(a,"rewriter.getI32IntegerAttr(1)"))'
mutate 2 "no abort: the failing side falls through to the continuation" \
  'import sys; p=sys.argv[1]; s=open(p).read(); a="    rewriter.create<LLVM::CallOp>(loc, abortFn, ValueRange{});\n    rewriter.create<LLVM::UnreachableOp>(loc);\n"; assert a in s; open(p,"w").write(s.replace(a,"    rewriter.create<cf::BranchOp>(loc, cont);\n"))'
mutate 3 "the func.func-parent guard removed" \
  'import sys; p=sys.argv[1]; s=open(p).read(); a="    if (!isa<func::FuncOp>(op->getParentOp()))\n      return rewriter.notifyMatchFailure(op, \"assert is not directly inside a func.func\");\n"; assert a in s; open(p,"w").write(s.replace(a,""))'
mutate 4 "message length off by two (the last character and the newline are cut)" \
  'import sys; p=sys.argv[1]; s=open(p).read(); a="rewriter.getI64IntegerAttr(text.size())"; assert a in s; open(p,"w").write(s.replace(a,"rewriter.getI64IntegerAttr(text.size() - 2)"))'
mutate 5 "branch targets swapped: a TRUE condition goes to the failing side, so VALID programs abort" \
  'import sys; p=sys.argv[1]; s=open(p).read(); a="op.getArg(), cont, ValueRange{}, fail, ValueRange{}"; assert a in s; open(p,"w").write(s.replace(a,"op.getArg(), fail, ValueRange{}, cont, ValueRange{}"))'
mutate 6 "the pass declares @abort even when there is no assert to rewrite (it alters programs it should leave alone)" \
  'import sys; p=sys.argv[1]; s=open(p).read(); a="    RewritePatternSet patterns(&getContext());\n"; assert a in s; open(p,"w").write(s.replace(a, "    getOrDeclare(getOperation(), \"abort\", LLVM::LLVMVoidType::get(&getContext()), {});\n"+a))'
mutate 7 "global names always start at 0 again (the uniqueness search is removed): a second run collides" \
  'import sys; p=sys.argv[1]; s=open(p).read(); a="      if (!module.lookupSymbol(name))\n        break;\n"; assert a in s; open(p,"w").write(s.replace(a,"      break;\n"))'
