#!/bin/sh
# Run every example through mgc and show the real output. Output: demo_out.txt
# (Memref base addresses differ from run to run; the tests ignore them.)
HERE=$(cd "$(dirname "$0")" && pwd); cd $HERE/examples
for f in 0[1-4]*.mg 0[6-9]*.mg 10*.mg; do
  echo "################ mgc run examples/$f"; sed 's/^/  | /' $f; echo "  ----- output"
  ../mgc run $f 2>&1 | sed 's/base@ = 0x[0-9a-f]*/base@ = 0x…/'; echo "  ----- exit status $(../mgc run $f >/dev/null 2>&1; echo $?)"; echo
done
echo "################ mgc ptx examples/05_gpu.mg"; sed 's/^/  | /' 05_gpu.mg; echo "  ----- output (first 30 lines)"; ../mgc ptx 05_gpu.mg | head -30; echo
for f in errors/*.mg; do echo "################ mgc run examples/$f"; sed 's/^/  | /' $f; echo "  ----- output"; ../mgc run $f 2>&1; echo "  ----- exit status $(../mgc run $f >/dev/null 2>&1; echo $?)"; echo; done
