#!/bin/sh
# Rebuild mg-opt with one bug injected into LowerToAffine.cpp and run the ops tests against it.
# Each build is a full rebuild in work/mutN (about two minutes). Output: lowering_mutation_out.txt
HERE=$(cd "$(dirname "$0")" && pwd); LIT=$HERE/../../part15/code; M=$HERE/work/mut; rm -rf $M; mkdir -p $M
n=0
try() {  # label sed-expr
  n=$((n+1)); d=$M/$n; mkdir -p $d/build; cp -r $HERE/tree $d/tree; rm -rf $d/tree/build
  cp $d/tree/lib/LowerToAffine.cpp $d/before.cpp; sed -i "$2" $d/tree/lib/LowerToAffine.cpp
  if cmp -s $d/before.cpp $d/tree/lib/LowerToAffine.cpp; then echo "### $1: MUTATION DID NOT APPLY"; return; fi
  ( cd $d/build && cmake $d/tree -DMLIR_DIR=/usr/lib/llvm-18/lib/cmake/mlir -DLLVM_DIR=/usr/lib/llvm-18/lib/cmake/llvm -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=OFF >/dev/null 2>&1 && mkdir -p include/mg && make -j8 >/dev/null 2>&1 )
  [ -x $d/build/mg-opt ] || { echo "### $1: BUILD FAILED"; return; }
  printf '%s\n' "### lowering mutation: $1"
  MG_OPT=$d/build/mg-opt MG_TEST_TMP=$d/out sh $LIT/run_lit.sh --filter ':: ops/' 2>&1 | grep -E "^(FAIL)|  Passed|  Failed" | sed 's#IR Forge / Mountain Goat :: ##'
}
try "matmul accumulator not zero-filled"             's/b.create<affine::AffineStoreOp>(l, zero, alloc, ivs);/(void)zero;/'
try "scalar op ignores reversed (10 - x computed as x - 10)" 's/Value lhs = rev ? c : x, rhs = rev ? x : c, r;/Value lhs = x, rhs = c, r;/'
try "matmul skips the run-time inner-dimension check" 's/if (lt.isDynamicDim(1) || rt.isDynamicDim(0)) {/if (false) {/'
try "mg.div lowered as a multiply"                   's/ElementwiseBinaryLowering<mg::DivOp, arith::DivFOp>/ElementwiseBinaryLowering<mg::DivOp, arith::MulFOp>/'
try "mg.neg lowered as identity (no negation)"        's/b.create<arith::NegFOp>(l, x)/x/'
# Added after an independent review (Chapter 21's "After the review" section):
try "elementwise operands swapped (computes rhs OP lhs)"  's/b.create<affine::AffineStoreOp>(l, b.create<ArithOp>(l, x, y), alloc, ivs);/b.create<affine::AffineStoreOp>(l, b.create<ArithOp>(l, y, x), alloc, ivs);/'
try "elementwise drops its run-time shape check"          '/struct ElementwiseBinaryLowering/,/^};/ s/mg::dyn::assertSameShape(rewriter, loc, lhs, rhs,/if (false) mg::dyn::assertSameShape(rewriter, loc, lhs, rhs,/'
try "matmul takes n from the wrong operand (lhs dim 1)"  's/Value n = bound(outType.getDimSize(1), rhs, 1, Value());/Value n = bound(outType.getDimSize(1), lhs, 1, Value());/'

