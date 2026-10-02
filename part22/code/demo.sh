#!/bin/sh
# Run every Chapter 22 example through mgc and show the real output. Output: demo_out.txt
# (Memref base addresses differ from run to run and are masked.)
HERE=$(cd "$(dirname "$0")" && pwd); cd $HERE/examples
for f in 0*.mg 11*.mg 12*.mg 13*.mg; do
  echo "################ ./mgc run examples/$f"; sed 's/^/  | /' $f; echo "  ----- output"
  ../mgc run $f 2>&1 | sed 's/base@ = 0x[0-9a-f]*/base@ = 0x…/'; echo "  ----- exit status $(../mgc run $f >/dev/null 2>&1; echo $?)"; echo
done
echo "################ ./mgc ptx examples/10_gpu_layer.mg"; sed 's/^/  | /' 10_gpu_layer.mg; echo "  ----- kernel entry points and the arithmetic (one kernel per loop nest)"
../mgc ptx 10_gpu_layer.mg | grep -E "\.entry|(add|sub|mul|div|max)\.[A-Za-z.]*f64|ld\.global\.f64|st\.global\.f64" | sed 's/^\t//'; echo
for f in errors/*.mg; do echo "################ ./mgc run examples/$f"; sed 's/^/  | /' $f; echo "  ----- output"; ../mgc run $f 2>&1; echo "  ----- exit status $(../mgc run $f >/dev/null 2>&1; echo $?)"; echo; done
