#!/bin/sh
# READ THIS FIRST: this script breaks the Chapter 38 code on purpose, one way at a time, and re-runs the Chapter 38 tests (test/outline38).
#   "caught by ..." (a test failed) is the EXPECTED, wanted result: it shows the tests can notice that mistake.
#   "NOT CAUGHT" would be a test gap. Part 1 edits the driver (mgc) in place; part 2 rebuilds mg-opt with one bug injected into OutlineLoops.cpp (a full rebuild each, in
#   work/mut/N, about a minute). Every edited file is restored afterwards. Output: mutation_out.txt
HERE=$(cd "$(dirname "$0")" && pwd); LIT=$HERE/../../part15/code/run_lit.sh; W=$HERE/work/mut; rm -rf $W; mkdir -p $W
FILTER=':: outline38/'
echo "NOTE: this script deliberately breaks the compiler code. 'caught' lines are EXPECTED: they show the tests can detect the mistake."
G=$HERE/mgc; cp $G $W/mgc.orig
restore() { cp $W/mgc.orig $G; }
trap restore EXIT
fails_of() { grep '^FAIL' | sed 's/.*:: //; s/ (.*//' | tr '\n' ' '; }
out=$(MG_TEST_TMP=$W/out sh $LIT --filter "$FILTER" 2>&1); echo "baseline (nothing broken): $(echo "$out" | grep -q '^FAIL' && echo 'UNEXPECTED FAILURE' || echo 'tests pass (expected)')"
echo; echo "== Part 1: the driver"
fe() {  # label sed-expr
  restore; sed -i "$2" $G
  if cmp -s $G $W/mgc.orig; then echo "$1: MUTATION DID NOT APPLY"; return; fi
  f=$(MG_TEST_TMP=$W/out sh $LIT --filter "$FILTER" 2>&1 | fails_of)
  if [ -n "$f" ]; then echo "$1: caught by $f"; else echo "$1: NOT CAUGHT (a test gap)"; fi
  restore
}
fe "--outline is accepted but does nothing"                                  's/--outline) OUTLINE=--mg-outline-loops; shift;;/--outline) OUTLINE=; shift;;/'
fe "--outline runs the pass BEFORE the loops exist (ahead of --convert-mg-to-affine)" 's/--convert-mg-to-affine$CONVOPT $PASSES $OUTLINE -o/$OUTLINE --convert-mg-to-affine$CONVOPT $PASSES -o/'
restore

echo; echo "== Part 2: the pass (a full rebuild per mutation)"
n=0
try() {  # label sed-expr
  n=$((n+1)); d=$W/$n; mkdir -p $d/build; cp -r $HERE/tree $d/tree; rm -rf $d/tree/build
  tgt=$d/tree/lib/OutlineLoops.cpp; cp $tgt $d/before; sed -i "$2" $tgt
  if cmp -s $d/before $tgt; then echo "$1: MUTATION DID NOT APPLY"; return; fi
  ( cd $d/build && cmake $d/tree -DMLIR_DIR=/usr/lib/llvm-18/lib/cmake/mlir -DLLVM_DIR=/usr/lib/llvm-18/lib/cmake/llvm -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=OFF >/dev/null 2>&1 && mkdir -p include/mg && make -j8 >/dev/null 2>&1 )
  [ -x $d/build/mg-opt ] || { echo "$1: BUILD FAILED"; return; }
  f=$(MG_OPT=$d/build/mg-opt MG_TEST_TMP=$d/out sh $LIT --filter "$FILTER" 2>&1 | fails_of)
  if [ -n "$f" ]; then echo "$1: caught by $f"; else echo "$1: NOT CAUGHT (a test gap)"; fi
}
try "the original loop nest is not erased (every nest would run twice)"            's|        forOp.erase();|        // forOp.erase();|'
try "the call passes its arguments in reverse order"                                's|cb.create<func::CallOp>(loc, callee, args.getArrayRef());|cb.create<func::CallOp>(loc, callee, SmallVector<Value>(args.rbegin(), args.rend()));|'
try "deduplication is switched off (every nest gets its own function)"              's|auto it = known.find(key);|auto it = known.end();|'
try "every nest hashes to the same key (all nests share the first function)"        's|callee.print(os);|os << "same";|'
try "the min-loops threshold is ignored"                                            's|if ((int)nests.size() < minLoops) continue;||'
try "the threshold is off by one (a function with exactly min-loops nests is skipped)" 's|(int)nests.size() < minLoops|(int)nests.size() <= minLoops|'
try "constants are not cloned into the outlined function"                           's|for (arith::ConstantOp c : consts) b.clone(\*c, map);||'
try "block arguments (function arguments, run-time sizes) count as defined inside"  's|return !forOp->isAncestor(owner);|return v.getDefiningOp() != nullptr \&\& !forOp->isAncestor(owner);|'
try "outlined functions are public, not private"                                   's|callee.setPrivate();||'
restore
echo; echo "restored: $(cmp -s $G $W/mgc.orig && echo 'mgc is back to its original' || echo 'RESTORE FAILED')"
