#!/bin/sh
# Show that the Chapter 20 tests can fail: (1) against Chapter 19's mg-opt (no tensor.cast lowering),
# (2) against four deliberately broken copies of the front end / driver. Output: prove_tests_can_fail_out.txt
# READ THIS FIRST: this script runs the Chapter 20 tests against an older build and against deliberately broken copies of the front end and driver.
#   FAIL lines (and non-zero exit statuses) in this script's output are the EXPECTED result: each broken copy SHOULD make at least one test fail (a FAIL line means a test caught the bug). The "baseline" sections must show all tests passing.
#   The unmodified, current build is the baseline and must show no failures. A mutation or old build that makes NO test fail would be the problem.
echo "NOTE: this script deliberately runs broken or older code. FAIL lines below are EXPECTED: they show the tests can detect the problem. The baseline (unmodified current build) must show none."
HERE=$(cd "$(dirname "$0")" && pwd); LIT=$HERE/../../part15/code; W=$HERE/work/prove; rm -rf $W; mkdir -p $W
run() {  # label, env...   -> prints which frontend tests failed
  printf '%s\n' "### $1"; shift
  env "$@" MG_TEST_TMP=$W/out sh $LIT/run_lit.sh --filter frontend 2>&1 | grep -E "^(FAIL|  Passed|  Failed)" | sed 's#IR Forge / Mountain Goat :: ##'
}
run "baseline: Chapter 20 build" MG_OPT=$HERE/build/mg-opt
run "Chapter 19 build (no tensor.cast lowering)" MG_OPT=$HERE/../../part19/code/build/mg-opt
# Broken copies: the lit config reads mgc/mgfront from part20/code, so mutate in place and always restore.
cp $HERE/mgfront.py $W/mgfront.orig; cp $HERE/mgc $W/mgc.orig
restore() { cp $W/mgfront.orig $HERE/mgfront.py; cp $W/mgc.orig $HERE/mgc; }
trap restore EXIT
mutate() {  # label file sed-expr
  restore; cp $2 $W/before; sed -i "$3" $2
  if cmp -s $2 $W/before; then echo "### $1: MUTATION DID NOT APPLY"; return; fi
  run "mutation: $1" MG_OPT=$HERE/build/mg-opt
}
mutate "front end stops checking static add shapes" $HERE/mgfront.py 's/if a is not None and b is not None and a != b:/if False:/'
mutate "front end drops tensor.cast for dynamic calls" $HERE/mgfront.py 's/if s != p:  # static/if False:  # static/'
mutate "driver forgets Chapter 19's stderr pass" $HERE/mgc "s/ --mg-lower-assert-to-stderr//"
mutate "driver links without the runtime printer" $HERE/mgc 's/ -lmlir_runner_utils//'
restore; echo "### restored"; run "baseline again" MG_OPT=$HERE/build/mg-opt
