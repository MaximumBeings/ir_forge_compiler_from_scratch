#!/bin/sh
# Chapter 38: run every example without and with --outline, show both outputs (the memory address in the printed descriptor changes from run to run, so it is replaced by 0x…),
# and count the loop nests, outlined functions and calls in the kept affine IR. Output: examples_out.txt
HERE=$(cd "$(dirname "$0")" && pwd); cd $HERE/examples; W=$HERE/work/ex; mkdir -p $W
norm() { sed 's/base@ = 0x[0-9a-f]*/base@ = 0x…/'; }
for f in 0*.mg; do
  n=$(basename $f .mg)
  echo "################ $f"; cut -c1-200 $f | sed 's/^/  | /' | head -12; [ $(wc -l < $f) -gt 12 ] && echo "  | ... ($(wc -l < $f) lines in all)"
  echo "  ----- mgc run $f"; ../mgc run $f 2>&1 | norm | tail -n +1 | head -14
  echo "  ----- mgc run $f --outline"; ../mgc run $f --outline 2>&1 | norm | head -14
  rm -rf $W/$n; MGC_KEEP=$W/$n ../mgc build $f -o $W/$n.exe >/dev/null; MGC_KEEP=$W/$n.o ../mgc build $f --outline -o $W/$n.o.exe >/dev/null
  echo "  ----- the kept affine IR: plain has $(grep -c 'affine.for' $W/$n/$n.affine.mlir) affine.for ($(grep -c '^    affine.for' $W/$n/$n.affine.mlir) at the top of a function body); with --outline: $(grep -c 'func.func private @mg_outlined' $W/$n.o/$n.affine.mlir) outlined functions, $(grep -c 'call @mg_outlined' $W/$n.o/$n.affine.mlir) calls, $(grep -c 'affine.for' $W/$n.o/$n.affine.mlir) affine.for in all"
  echo
done
