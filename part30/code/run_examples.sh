#!/bin/sh
# Run every Chapter 30 example with this chapter's driver, then the eight error examples. Output: examples_out.txt
# (A memory address in the printed descriptor changes from run to run, so it is replaced by 0x… to keep the output reproducible.)
HERE=$(cd "$(dirname "$0")" && pwd); cd $HERE/examples
for f in 0*.mg errors/e*.mg; do
  echo "################ mgc run $f"; n=$(wc -l < $f); if [ $n -gt 30 ]; then echo "  | ($n lines: the definitions are transformer.mg.defs, followed by seeded weights, the token ids and the calls; see the file)"; else sed 's/^/  | /' $f | cut -c1-230; fi; echo "  ----- output"
  ../mgc run $f 2>&1 | sed 's/base@ = 0x[0-9a-f]*/base@ = 0x…/'; echo "  ----- exit status $(../mgc run $f >/dev/null 2>&1; echo $?)"; echo
done
