#!/bin/sh
# Run the gallery examples (07 onward) with the Chapter 22 driver, and the three extra error examples. Output: gallery_out.txt
HERE=$(cd "$(dirname "$0")" && pwd); MGC=$HERE/../../part22/code/mgc; cd $HERE
for f in 07_*.mg 08_*.mg 09_*.mg 10_*.mg 11_*.mg 12_*.mg 13_*.mg 14_*.mg 15_*.mg 16_*.mg errors/e10_*.mg errors/e11_*.mg errors/e12_*.mg; do
  echo "################ mgc run $f"; sed 's/^/  | /' $f; echo "  ----- output"
  $MGC run $f 2>&1 | sed 's/base@ = 0x[0-9a-f]*/base@ = 0x…/'; echo "  ----- exit status $($MGC run $f >/dev/null 2>&1; echo $?)"; echo
done
