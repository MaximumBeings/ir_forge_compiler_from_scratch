#!/bin/sh
# READ THIS FIRST: this script breaks the Chapter 32 code on purpose, one way at a time, and re-runs the Chapter 32 tests (test/generalize32).
#   "caught by ..." (a test failed) is the EXPECTED, wanted result: it shows the tests can notice that mistake.
#   "NOT CAUGHT" would be a test gap. Part 1 edits the front end (mgfront.py) and the driver (mgc) in place; part 2 rebuilds mg-opt with one bug
#   injected into the dialect or the lowering (a full rebuild each, in work/mut/N). Every edited file is restored afterwards. Output: mutation_out.txt
HERE=$(cd "$(dirname "$0")" && pwd); LIT=$HERE/../../part15/code/run_lit.sh; W=$HERE/work/mut; rm -rf $W; mkdir -p $W
FILTER=':: generalize32/'
echo "NOTE: this script deliberately breaks the compiler code. 'caught' lines are EXPECTED: they show the tests can detect the mistake."
F=$HERE/mgfront.py; G=$HERE/mgc; cp $F $W/mgfront.orig; cp $G $W/mgc.orig
restore() { cp $W/mgfront.orig $F; cp $W/mgc.orig $G; }
trap restore EXIT
fails_of() { grep '^FAIL' | sed 's/.*:: //; s/ (.*//' | tr '\n' ' '; }
out=$(MG_TEST_TMP=$W/out sh $LIT --filter "$FILTER" 2>&1); echo "baseline (nothing broken): $(echo "$out" | grep -q '^FAIL' && echo 'UNEXPECTED FAILURE' || echo 'tests pass (expected)')"
echo; echo "== Part 1: the front end and the driver"
fe() {  # label file sed-expr
  restore; sed -i "$3" $2
  if cmp -s $F $W/mgfront.orig && cmp -s $G $W/mgc.orig; then echo "$1: MUTATION DID NOT APPLY"; return; fi
  f=$(MG_TEST_TMP=$W/out sh $LIT --filter "$FILTER" 2>&1 | fails_of)
  if [ -n "$f" ]; then echo "$1: caught by $f"; else echo "$1: NOT CAUGHT (a test gap)"; fi
  restore
}
fe "ge is compiled as a subtraction by the front end"                   $F 's/{r} = mg.ge {a}, {b}/{r} = mg.sub {a}, {b}/'
restore

echo; echo "== Part 2: the dialect verifier and the lowering (a full rebuild per mutation)"
n=0
try() {  # label file sed-expr
  n=$((n+1)); d=$W/$n; mkdir -p $d/build; cp -r $HERE/tree $d/tree; rm -rf $d/tree/build
  tgt=$d/tree/lib/$2; cp $tgt $d/before; sed -i "$3" $tgt
  if cmp -s $d/before $tgt; then echo "$1: MUTATION DID NOT APPLY"; return; fi
  ( cd $d/build && cmake $d/tree -DMLIR_DIR=/usr/lib/llvm-18/lib/cmake/mlir -DLLVM_DIR=/usr/lib/llvm-18/lib/cmake/llvm -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=OFF >/dev/null 2>&1 && mkdir -p include/mg && make -j8 >/dev/null 2>&1 )
  [ -x $d/build/mg-opt ] || { echo "$1: BUILD FAILED"; return; }
  f=$(MG_OPT=$d/build/mg-opt MG_TEST_TMP=$d/out sh $LIT --filter "$FILTER" 2>&1 | fails_of)
  if [ -n "$f" ]; then echo "$1: caught by $f"; else echo "$1: NOT CAUGHT (a test gap)"; fi
}
try "ge compares with > instead of >= (a maximum no longer ties with itself)" LowerToAffine.cpp 's/arith::CmpFPredicate::OGE/arith::CmpFPredicate::OGT/'
try "ge compares with <= instead of >="                                  LowerToAffine.cpp 's/arith::CmpFPredicate::OGE/arith::CmpFPredicate::OLE/'
try "ge returns 0 where true and 1 where false (the select is swapped)"  LowerToAffine.cpp 's/b.create<arith::SelectOp>(l, cond, one, zero)/b.create<arith::SelectOp>(l, cond, zero, one)/'
try "ge returns 2 where true"                                            LowerToAffine.cpp 's/Value one = rewriter.create<arith::ConstantOp>(loc, rewriter.getF64FloatAttr(1.0));/Value one = rewriter.create<arith::ConstantOp>(loc, rewriter.getF64FloatAttr(2.0));/'
try "mg.ge's verifier accepts anything"                                  MgDialect.cpp 's/return verifyElementwise(\*this, {getLhs().getType(), getRhs().getType(), getResult().getType()}, "mg.ge"); }/return mlir::success(); }/'
try "a sum starts from 1 instead of 0 (every row_sum and col_sum is off by one)" LowerToAffine.cpp 's/double initVal = isMax ? -std::numeric_limits<double>::infinity() : 0.0;/double initVal = isMax ? -std::numeric_limits<double>::infinity() : 1.0;/'
restore
echo; echo "restored: $(cmp -s $F $W/mgfront.orig && cmp -s $G $W/mgc.orig && echo 'mgfront.py and mgc are back to their originals' || echo 'RESTORE FAILED')"
