#!/bin/sh
# The intermediate artifacts of one program (examples/03_dynamic.mg) at every stage of mgc. Output: show/
HERE=$(cd "$(dirname "$0")" && pwd); O=$HERE/show; mkdir -p $O
MGC_KEEP=$O/stages $HERE/mgc build $HERE/examples/03_dynamic.mg -o $O/stages/03.exe
cp $O/stages/03_dynamic.mlir $O/1_front_end.mlir
cp $O/stages/03_dynamic.affine.mlir $O/2_after_convert_mg_to_affine.mlir
cp $O/stages/03_dynamic.llvm.mlir $O/3_llvm_dialect.mlir
cp $O/stages/03_dynamic.ll $O/4_llvm_ir.ll
for f in $O/1_front_end.mlir $O/2_after_convert_mg_to_affine.mlir $O/3_llvm_dialect.mlir $O/4_llvm_ir.ll; do printf '%6d lines  %s\n' $(wc -l < $f) $(basename $f); done > $O/stage_sizes.txt
echo "write(2,... calls in stage 4: $(grep -c 'call .*@write' $O/4_llvm_ir.ll);  puts calls: $(grep -c 'call .*@puts' $O/4_llvm_ir.ll)" >> $O/stage_sizes.txt
rm -rf $O/stages
