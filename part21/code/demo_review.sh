#!/bin/sh
# The examples added after the independent review (see Chapter 21). Output: demo_review_out.txt
HERE=$(cd "$(dirname "$0")" && pwd); cd $HERE/examples
for f in 15_elementwise_mismatch 15b_mul_mismatch 15c_div_mismatch 16_negate 17_dynamic_divide; do
  echo "################ ./mgc run examples/$f.mg"; sed 's/^/  | /' $f.mg; echo "  ----- output"
  ../mgc run $f.mg 2>&1 | sed 's/base@ = 0x[0-9a-f]*/base@ = 0x…/'; echo "  ----- exit status $(../mgc run $f.mg >/dev/null 2>&1; echo $?)"; echo
done
