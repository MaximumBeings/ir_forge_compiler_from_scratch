#!/bin/sh
# Show that the Chapter 21 tests (test/ops) can fail. Output: prove_tests_can_fail_out.txt
#  (1) against Chapter 20's mg-opt, which has none of the new ops;
#  (2) against broken copies of the front end (no rebuild needed; restored on exit);
#  (3) against rebuilt mg-opt copies with a bug injected into the new lowering (lowering_mutation.sh).
# READ THIS FIRST: this script runs the Chapter 21 tests against an older build and against deliberately broken copies of the front end and driver.
#   FAIL lines (and non-zero exit statuses) in this script's output are the EXPECTED result: each broken copy SHOULD make at least one test fail (a FAIL line means a test caught the bug). The "baseline" sections must show all tests passing.
#   The unmodified, current build is the baseline and must show no failures. A mutation or old build that makes NO test fail would be the problem.
echo "NOTE: this script deliberately runs broken or older code. FAIL lines below are EXPECTED: they show the tests can detect the problem. The baseline (unmodified current build) must show none."
HERE=$(cd "$(dirname "$0")" && pwd); LIT=$HERE/../../part15/code; W=$HERE/work/prove; rm -rf $W; mkdir -p $W
run() { label=$1; mgopt=$2
  printf '%s\n' "### $label"
  MG_OPT=$mgopt MG_TEST_TMP=$W/out sh $LIT/run_lit.sh --filter ':: ops/' 2>&1 | grep -E "^(FAIL)|  Passed|  Failed" | sed 's#IR Forge / Mountain Goat :: ##'
}
run "baseline: Chapter 21 build" $HERE/build/mg-opt
run "Chapter 20 build (none of the new ops exist)" $HERE/../../part20/code/build/mg-opt
cp $HERE/mgfront.py $W/mgfront.orig; cp $HERE/mgc $W/mgc.orig
restore() { cp $W/mgfront.orig $HERE/mgfront.py; cp $W/mgc.orig $HERE/mgc; }
trap restore EXIT
mutate() {  # label file sed-expr
  restore; cp $2 $W/before; sed -i "$3" $2
  if cmp -s $2 $W/before; then echo "### $1: MUTATION DID NOT APPLY"; return; fi
  run "front-end/driver mutation: $1" $HERE/build/mg-opt
}
mutate "'-' is emitted as mg.add"                       $HERE/mgfront.py 's/OPNAME = {"+": "add", "-": "sub"/OPNAME = {"+": "add", "-": "add"/'
mutate "'*' and '@' swapped (Hadamard vs matmul)"       $HERE/mgfront.py 's/if op == "@":/if op == "*":/'
mutate "scalar on the left is not marked reversed"      $HERE/mgfront.py 's/rev = v is None/rev = False/'
mutate "'*' and '+' on the same precedence level"       $HERE/mgfront.py 's/while self.peek()\[1\] in ("\*", "\/", "@"):/while self.peek()[1] in ("*", "\/", "@", "+"):/'
mutate "matmul result shape is (m, k) instead of (m, n)" $HERE/mgfront.py 's/shape = (s\[0\], s2\[1\]); r = self.fn.tmp()/shape = (s[0], s[1]); r = self.fn.tmp()/'
mutate "driver forgets convert-scf-to-cf for the GPU path" $HERE/mgc 's/convert-scf-to-cf,convert-gpu-to-nvvm/convert-gpu-to-nvvm/'
restore; echo "### restored"; run "baseline again" $HERE/build/mg-opt
