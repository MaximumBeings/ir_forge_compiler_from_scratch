#!/bin/sh
# READ THIS FIRST: this script breaks the Chapter 29 code on purpose, one way at a time, and re-runs the Chapter 29 tests (test/attention29).
#   "caught by ..." (a test failed) is the EXPECTED, wanted result: it shows the tests can notice that mistake.
#   "NOT CAUGHT" would be a test gap. Part 1 edits the front end (mgfront.py) and the driver (mgc) in place; part 2 rebuilds mg-opt with one bug
#   injected into the dialect or the lowering (a full rebuild each, in work/mut/N). Every edited file is restored afterwards. Output: mutation_out.txt
HERE=$(cd "$(dirname "$0")" && pwd); LIT=$HERE/../../part15/code/run_lit.sh; W=$HERE/work/mut; rm -rf $W; mkdir -p $W
FILTER=':: attention29/'
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
fe "exp is compiled as relu by the front end"                            $F 's/{r} = mg.exp {v}/{r} = mg.relu {v}/'
fe "the driver forgets to lower the math dialect"                        $G 's/--convert-math-to-llvm //'
fe "the driver does not link the math library (-lm)"                     $G 's/ -lm / /'
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
try "exp computes e^(-x)"                                               LowerToAffine.cpp 's/b.create<math::ExpOp>(l, x)/b.create<math::ExpOp>(l, b.create<arith::NegFOp>(l, x))/'
try "exp copies its input (computes nothing)"                           LowerToAffine.cpp 's/b.create<math::ExpOp>(l, x)/x/'
try "mg.exp's verifier accepts anything"                                MgDialect.cpp 's/return verifyElementwise(\*this, {getInput().getType(), getResult().getType()}, "mg.exp"); }/return mlir::success(); }/'
try "a row maximum is computed as a minimum (Chapter 22's reduce)"       LowerToAffine.cpp 's/Value(b.create<arith::MaximumFOp>(l, acc, x))/Value(b.create<arith::MinimumFOp>(l, acc, x))/'
try "a maximum starts from 0, not -infinity (wrong for all-negative rows)" LowerToAffine.cpp 's/double initVal = isMax ? -std::numeric_limits<double>::infinity() : 0.0;/double initVal = 0.0;/'
restore
echo; echo "restored: $(cmp -s $F $W/mgfront.orig && cmp -s $G $W/mgc.orig && echo 'mgfront.py and mgc are back to their originals' || echo 'RESTORE FAILED')"
