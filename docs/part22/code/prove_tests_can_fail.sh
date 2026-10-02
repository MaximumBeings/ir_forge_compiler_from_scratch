#!/bin/sh
# Show that the Chapter 22 tests (test/broadcast) can fail. Output: prove_tests_can_fail_out.txt
#  (1) against Chapter 21's mg-opt, which has none of the new ops;
#  (2) against broken copies of the front end (restored on exit);
#  (3) lowering bugs are in lowering_mutation.sh (rebuilds mg-opt for each).
HERE=$(cd "$(dirname "$0")" && pwd); LIT=$HERE/../../part15/code; W=$HERE/work/prove; rm -rf $W; mkdir -p $W
run() { label=$1; mgopt=$2
  printf '%s\n' "### $label"
  MG_OPT=$mgopt MG_TEST_TMP=$W/out sh $LIT/run_lit.sh --filter ':: broadcast/' 2>&1 | grep -E "^(FAIL)|  Passed|  Failed" | sed 's#IR Forge / Mountain Goat :: ##'
}
run "baseline: Chapter 22 build" $HERE/build/mg-opt
run "Chapter 21 build (none of the new ops exist)" $HERE/../../part21/code/build/mg-opt
cp $HERE/mgfront.py $W/mgfront.orig; cp $HERE/mgc $W/mgc.orig
restore() { cp $W/mgfront.orig $HERE/mgfront.py; cp $W/mgc.orig $HERE/mgc; }
trap restore EXIT
mutate() {  # label file sed-expr
  restore; cp $2 $W/before; sed -i "$3" $2
  if cmp -s $2 $W/before; then echo "### $1: MUTATION DID NOT APPLY"; return; fi
  run "front-end mutation: $1" $HERE/build/mg-opt
}
mutate "row_* and col_* use the opposite axis"          $HERE/mgfront.py 's/axis = 1 if name.startswith("row_") else 0/axis = 0 if name.startswith("row_") else 1/'
mutate "mean divides by the wrong dimension's count"    $HERE/mgfront.py 's/mlir_float(str(s\[axis\]))/mlir_float(str(s[1 - axis]))/'
mutate "relu is emitted as negation"                    $HERE/mgfront.py 's/mg.relu {v} : {fmt(s)} -> {fmt(s)}/mg.neg {v} : {fmt(s)} -> {fmt(s)}/'
mutate "a size-1 left operand is not broadcast"         $HERE/mgfront.py 's/            elif a == 1: target.append(b)/            elif False: target.append(b)/'
mutate "a 1x1 right operand is never broadcast"         $HERE/mgfront.py 's/            elif b == 1: target.append(a)/            elif False: target.append(a)/'
restore; echo "### restored"; run "baseline again" $HERE/build/mg-opt
