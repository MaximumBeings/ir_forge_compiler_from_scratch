#!/bin/sh
# READ THIS FIRST: this script runs ci.sh against an OLDER compiler build (Chapter 14's) on purpose.
#   The failures and the "CI FAILED" line in its output are the EXPECTED result: they show that CI really does fail (exit status 1)
#   when the tests fail, instead of reporting success no matter what. The normal run (ci_run_out.txt) must pass.
# Needs docs/part14/code/build.sh to have been run. Output: ci_failure_demo_out.txt
echo "NOTE: this script deliberately tests an old compiler build. FAIL lines and 'CI FAILED' below are EXPECTED: they show CI can fail."
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
cd "$ROOT"
CI_SKIP_BUILD=1 CI_SKIP_DOCS=1 MG_OPT=$ROOT/docs/part14/code/build/mg-opt ./ci.sh > /tmp/ci_demo.$$ 2>&1
status=$?
echo "--- a few of the failing tests (the old build lacks features the current tests check):"
grep -E "^FAIL:" /tmp/ci_demo.$$ | sed 's/IR Forge \/ Mountain Goat :: //; s/ ([0-9]* of [0-9]*)//' | sort -u | head -8
echo "--- the suite's own totals:"
grep -E "^  (Passed|Failed)" /tmp/ci_demo.$$
echo "--- ci.sh's summary:"
sed -n '/^CI summary:/,$p' /tmp/ci_demo.$$
echo "exit status of ci.sh: $status   (0 = CI passes, 1 = CI fails; here 1 is the expected result)"
rm -f /tmp/ci_demo.$$
