#!/bin/sh
# Chapter 38: what the pass leaves behind, for examples/02_one_nest_forty_times.mg: the one outlined function, and the start and end of `main` before and after. Output: show_ir_out.txt
HERE=$(cd "$(dirname "$0")" && pwd); W=$HERE/work/show; rm -rf $W; mkdir -p $W; P=$HERE/examples/02_one_nest_forty_times.mg
MGC_KEEP=$W/plain $HERE/mgc build $P -o $W/p.exe >/dev/null; MGC_KEEP=$W/out $HERE/mgc build $P --outline -o $W/o.exe >/dev/null
echo "---- before (plain): the first loop nest in main, written out in place (the zero-initialisation and constant stores that come first are omitted)"
awk '/^    affine.for/{p=1} p{print} /^    }/{if(p){exit}}' $W/plain/02_one_nest_forty_times.affine.mlir
echo "---- after (--outline): the outlined function"
awk '/func.func private @mg_outlined_0/{p=1} p{print} /^  }/{if(p){exit}}' $W/out/02_one_nest_forty_times.affine.mlir
echo "---- after (--outline): the first three and the last of the 39 calls in main"
grep "call @mg_outlined" $W/out/02_one_nest_forty_times.affine.mlir | sed -n '1,3p;$p'
