#!/bin/sh
# Three deliberate source bugs, each applied to a COPY of Chapter 14's source tree, built, and tested.
# Needs ../../part14/code/build.sh to have been run (it creates the tree/ directory this copies).
set -e
HERE=$(cd "$(dirname "$0")" && pwd); SRC=$HERE/../../part14/code/tree
mutate() {  # name, python edit snippet (operates on files under $1)
  name=$1; W=$HERE/work/mut-$name; rm -rf "$W"; mkdir -p "$W/build/include/mg"; cp -r "$SRC" "$W/tree"
  python3 -c "$2" "$W/tree"
  (cd "$W/build" && cmake "$W/tree" -DMLIR_DIR=/usr/lib/llvm-18/lib/cmake/mlir -DLLVM_DIR=/usr/lib/llvm-18/lib/cmake/llvm \
     -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=OFF >/dev/null 2>&1 && make -j8 2>&1 | grep -E " error " || true)
  MG_OPT=$W/build/mg-opt MG_TEST_TMP=$W/out lit "$HERE/test" 2>&1 | grep -E "^FAIL|Passed|Failed:" | sed 's/IR Forge \/ Mountain Goat :: //;s/ ([0-9]* of [0-9]*)//' | sort -u
}
echo "##### MUTATION 1: canonicalizer's exact-type guard removed"
mutate 1 'import sys; p=sys.argv[1]+"/lib/MgDialect.cpp"; s=open(p).read(); a="    if (innerTranspose.getInput().getType() != op.getType())\n      return mlir::failure();\n"; assert a in s; open(p,"w").write(s.replace(a,""))'
echo; echo "##### MUTATION 2: runtime check only covers dimension 0"
mutate 2 'import sys; p=sys.argv[1]+"/include/mg/DynamicShapes.h"; s=open(p).read(); a="  for (int64_t d = 0; d < lhsType.getRank(); ++d) {\n    if (!lhsType.isDynamicDim(d) && !rhsType.isDynamicDim(d))"; assert a in s; open(p,"w").write(s.replace(a,a.replace("d < lhsType.getRank()","d < 1")))'
echo; echo "##### MUTATION 3: bufferization path forgets to emit the check"
mutate 3 'import sys; p=sys.argv[1]+"/lib/MgBufferizableOpInterfaceImpl.cpp"; s=open(p).read(); i=s.index("    mg::dyn::assertSameShape("); j=s.index("\n    llvm::SmallVector<Value, 2> extents;", i); open(p,"w").write(s[:i]+s[j:])'
