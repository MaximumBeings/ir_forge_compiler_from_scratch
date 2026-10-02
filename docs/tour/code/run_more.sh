#!/bin/sh
# Run the tour's extra examples (17 onward) with the Chapter 22 driver. Output: more_out.txt (a memory address is replaced by 0x… so the output is reproducible)
HERE=$(cd "$(dirname "$0")" && pwd); MGC=$HERE/../../part22/code/mgc; cd $HERE
for f in 17_*.mg 18_*.mg 19_*.mg 20_*.mg 21_*.mg 22_*.mg; do
  echo "################ mgc run $f"; sed 's/^/  | /' $f | cut -c1-200; echo "  ----- output"
  $MGC run $f 2>&1 | sed 's/base@ = 0x[0-9a-f]*/base@ = 0x…/'; echo "  ----- exit status $($MGC run $f >/dev/null 2>&1; echo $?)"; echo
done
