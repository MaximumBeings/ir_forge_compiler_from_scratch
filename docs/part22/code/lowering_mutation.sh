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
  MG_OPT=$d/build/mg-opt MG_TEST_TMP=$d/out sh $LIT/run_lit.sh --filter ':: broadcast/' 2>&1 | grep -E "^(FAIL)|  Passed|  Failed" | sed 's#IR Forge / Mountain Goat :: ##'
}
try "max reduction starts at 0 instead of -infinity"      's/double initVal = isMax ? -std::numeric_limits<double>::infinity() : 0.0;/double initVal = 0.0;/'
try "relu does not clamp (max of x with itself)"          's/b.create<arith::MaximumFOp>(l, x, zero)/b.create<arith::MaximumFOp>(l, x, x)/'
try "broadcast reads index 0 of the wrong dimension"      's/Value j = inType.getDimSize(1) == 1 ? zeroIdx : ivs\[1\];/Value j = inType.getDimSize(0) == 1 ? zeroIdx : ivs[1];/'
try "reduce over axis 1 writes into the wrong cell"        's/axis == 1 ? llvm::SmallVector<Value, 2>{i, zeroIdx}/axis == 1 ? llvm::SmallVector<Value, 2>{zeroIdx, i}/'
