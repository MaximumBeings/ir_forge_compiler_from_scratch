#!/bin/sh
# Run every tour example with the Chapter 21 driver. Output: tour_out.txt
HERE=$(cd "$(dirname "$0")" && pwd); MGC=$HERE/../../part22/code/mgc; cd $HERE
for f in 0*.mg; do
  echo "################ $MGC run $f" | sed "s#$MGC#mgc#"; sed 's/^/  | /' $f; echo "  ----- output"
  $MGC run $f 2>&1 | sed 's/base@ = 0x[0-9a-f]*/base@ = 0x…/'; echo "  ----- exit status $($MGC run $f >/dev/null 2>&1; echo $?)"; echo
done
for f in errors/*.mg; do
  echo "################ mgc run $f"; sed 's/^/  | /' $f; echo "  ----- output"; $MGC run $f 2>&1; echo "  ----- exit status $($MGC run $f >/dev/null 2>&1; echo $?)"; echo
done
