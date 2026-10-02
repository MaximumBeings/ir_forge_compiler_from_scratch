#!/bin/sh
# Run every Chapter 21 example through mgc and show the real output. Output: demo_out.txt
# (Memref base addresses differ from run to run and are masked.)
HERE=$(cd "$(dirname "$0")" && pwd); cd $HERE/examples
for f in 0[1-9]*.mg 1[0-2]*.mg; do
  echo "################ ./mgc run examples/$f"; sed 's/^/  | /' $f; echo "  ----- output"
  ../mgc run $f 2>&1 | sed 's/base@ = 0x[0-9a-f]*/base@ = 0x…/'; echo "  ----- exit status $(../mgc run $f >/dev/null 2>&1; echo $?)"; echo
done
for f in 13_gpu_matmul 14_gpu_ops; do
  echo "################ ./mgc ptx examples/$f.mg"; sed 's/^/  | /' $f.mg; echo "  ----- the PTX instructions that do the arithmetic, and the kernel entry points"
  ../mgc ptx $f.mg | grep -E "\.entry|(add|sub|mul|div)\.rn\.f64|ld\.global\.f64|st\.global\.f64" | sed 's/^\t//'; echo
done
for f in errors/*.mg; do echo "################ ./mgc run examples/$f"; sed 's/^/  | /' $f; echo "  ----- output"; ../mgc run $f 2>&1; echo "  ----- exit status $(../mgc run $f >/dev/null 2>&1; echo $?)"; echo; done
