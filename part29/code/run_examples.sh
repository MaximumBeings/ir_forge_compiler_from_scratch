#!/bin/sh
# Run every Chapter 29 example with this chapter's driver, then the eight error examples. Output: examples_out.txt
# (A memory address in the printed descriptor changes from run to run, so it is replaced by 0x… to keep the output reproducible.)
HERE=$(cd "$(dirname "$0")" && pwd); cd $HERE/examples
for f in 0*.mg errors/e*.mg; do
  echo "################ mgc run $f"; sed 's/^/  | /' $f | cut -c1-230; echo "  ----- output"
  ../mgc run $f 2>&1 | sed 's/base@ = 0x[0-9a-f]*/base@ = 0x…/'; echo "  ----- exit status $(../mgc run $f >/dev/null 2>&1; echo $?)"; echo
done
