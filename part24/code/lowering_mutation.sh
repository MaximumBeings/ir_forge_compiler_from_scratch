#!/bin/sh
# Rebuild mg-opt with one bug injected into LowerToAffine.cpp and run the ops tests against it.
# Each build is a full rebuild in work/mutN (about two minutes). Output: lowering_mutation_out.txt
# READ THIS FIRST: this script rebuilds mg-opt with one deliberate bug injected into the lowering at a time (a full rebuild each) and runs the tests.
#   FAIL lines (and non-zero exit statuses) in this script's output are the EXPECTED result: each bug SHOULD make at least one test fail (a FAIL line means a test caught it). A section with NO FAIL line would be a test gap.
#   The unmodified, current build is the baseline and must show no failures. A mutation or old build that makes NO test fail would be the problem.
echo "NOTE: this script deliberately runs broken or older code. FAIL lines below are EXPECTED: they show the tests can detect the problem. The baseline (unmodified current build) must show none."
HERE=$(cd "$(dirname "$0")" && pwd); LIT=$HERE/../../part15/code; M=$HERE/work/mut; rm -rf $M; mkdir -p $M
n=0
try() {  # label sed-expr
  n=$((n+1)); d=$M/$n; mkdir -p $d/build; cp -r $HERE/tree $d/tree; rm -rf $d/tree/build
  cp $d/tree/lib/LowerToAffine.cpp $d/before.cpp; sed -i "$2" $d/tree/lib/LowerToAffine.cpp
  if cmp -s $d/before.cpp $d/tree/lib/LowerToAffine.cpp; then echo "### $1: MUTATION DID NOT APPLY"; return; fi
  ( cd $d/build && cmake $d/tree -DMLIR_DIR=/usr/lib/llvm-18/lib/cmake/mlir -DLLVM_DIR=/usr/lib/llvm-18/lib/cmake/llvm -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=OFF >/dev/null 2>&1 && mkdir -p include/mg && make -j8 >/dev/null 2>&1 )
  [ -x $d/build/mg-opt ] || { echo "### $1: BUILD FAILED"; return; }
  printf '%s\n' "### lowering mutation: $1"
  MG_OPT=$d/build/mg-opt MG_TEST_TMP=$d/out sh $LIT/run_lit.sh --filter ':: loop-order/' 2>&1 | grep -E "^(FAIL)|  Passed|  Failed" | sed 's#IR Forge / Mountain Goat :: ##'
}
try "the ikj order is ignored (always lowers as ijk)"   's/: OpConversionPattern(converter, ctx), ikj(ikj) {}/: OpConversionPattern(converter, ctx), ikj(false) {}/'
try "ikj bounds not reordered (m, n, k used for i, k, j)"  's/ikj ? llvm::SmallVector<Value, 3>{m, k, n} : llvm::SmallVector<Value, 3>{m, n, k}/llvm::SmallVector<Value, 3>{m, n, k}/'
try "the right-hand matrix is read transposed"           's/Value y = b.create<affine::AffineLoadOp>(l, rhs, ValueRange{kk, j});/Value y = b.create<affine::AffineLoadOp>(l, rhs, ValueRange{j, kk});/'
try "the matmul-order option is not validated"           's/if (matmulOrder != "ijk" \&\& matmulOrder != "ikj") {/if (false) {/'

