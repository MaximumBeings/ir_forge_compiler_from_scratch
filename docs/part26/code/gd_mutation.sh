#!/bin/sh
# READ THIS FIRST: this script edits cpp/gd.mg to be WRONG, one way at a time, and re-runs the Chapter 26 test (test/learning).
#   A "caught" line (the test failed) is the EXPECTED, wanted result: it shows the test can notice that mistake.
#   "NOT CAUGHT" would be a test gap. gd.mg is restored afterwards. Output: gd_mutation_out.txt
HERE=$(cd "$(dirname "$0")" && pwd); D=$HERE/../..; LIT=$D/part15/code/run_lit.sh; F=$HERE/cpp/gd.mg; W=$HERE/work/mut; mkdir -p $W
echo "NOTE: this script deliberately breaks gd.mg. 'caught' lines are EXPECTED: they show the test can detect the mistake."
cp $F $W/original
run() { out=$(MG_TEST_TMP=$W/out sh $LIT --filter ':: learning/' 2>&1)
  if echo "$out" | grep -q '^FAIL'; then echo "$1: caught"; else echo "$1: NOT CAUGHT (a test gap)"; fi; }
mutate() {  # label sed-expr
  cp $W/original $F; sed -i "$2" $F
  if cmp -s $F $W/original; then echo "$1: MUTATION DID NOT APPLY"; else run "$1"; fi
  cp $W/original $F
}
echo "baseline (nothing broken): $(MG_TEST_TMP=$W/out sh $LIT --filter ':: learning/' 2>&1 | grep -q '^FAIL' && echo 'UNEXPECTED FAILURE' || echo 'test passes (expected)')"
mutate "update adds the gradient instead of subtracting it"        's/^def step\(.*\) = p - rate/def step\1 = p + rate/'
mutate "gradient has the wrong sign (y - x p)"                    's/^def grad\(.*\) = transpose(x) @ (x @ p - y)/def grad\1 = transpose(x) @ (y - x @ p)/'
mutate "the transpose is missing from the gradient"                's/^def grad\(.*\) = transpose(x) @/def grad\1 = x @/'
mutate "the learning rate is ignored"                              's/p - rate \* grad(x, y, p)/p - grad(x, y, p)/'
mutate "the gradient is twice too large (converges to the same answer)" 's/^def grad\(.*\) = transpose(x) @ (x @ p - y)/def grad\1 = 2 * (transpose(x) @ (x @ p - y))/'
mutate "the loss forgets to square the residuals"                  's/col_sum((x @ p - y) \* (x @ p - y))/col_sum(x @ p - y)/'
mutate "the loss sums the wrong way (row_sum)"                     's/col_sum((x @ p - y)/row_sum((x @ p - y)/'
echo "restored: $(cmp -s $F $W/original && echo 'gd.mg is back to its original' || echo 'RESTORE FAILED')"
