#!/bin/sh
# Regenerates the IR the chapter shows. Needs ../../part14/code/build.sh to have been run.
HERE=$(cd "$(dirname "$0")" && pwd); M=${MG_OPT:-$HERE/../../part14/code/build/mg-opt}; O=$HERE/show; mkdir -p $O
$M $HERE/chain.mlir --convert-mg-to-affine -o $O/chain_affine.mlir
$M $O/chain_affine.mlir --affine-loop-tile="tile-size=4" -o $O/chain_tile4.mlir
$M $O/chain_affine.mlir --affine-loop-unroll="unroll-factor=2" -o $O/chain_unroll2.mlir
$M $O/chain_affine.mlir --affine-loop-unroll="unroll-full" -o $O/chain_unroll_full.mlir
$M $O/chain_affine.mlir --affine-loop-fusion -o $O/chain_fusion.mlir
$M $HERE/chain2.mlir --convert-mg-to-affine -o $O/chain2_affine.mlir
$M $O/chain2_affine.mlir --affine-loop-unroll="unroll-full" -o $O/chain2_unroll_full.mlir
$M $HERE/static_chain.mlir --convert-mg-to-affine -o $O/static_chain_affine.mlir
$M $O/static_chain_affine.mlir --affine-loop-fusion -o $O/static_chain_fused.mlir
cmp -s $O/chain_affine.mlir $O/chain_unroll_full.mlir && echo "unroll-full on the dynamic chain left the IR byte-identical" > $O/unroll_full_noop.txt || echo "unroll-full CHANGED the dynamic chain" > $O/unroll_full_noop.txt
cmp -s $O/chain_affine.mlir $O/chain_fusion.mlir && echo "fusion on the dynamic chain left the IR byte-identical" > $O/fusion_noop.txt || echo "fusion CHANGED the dynamic chain" > $O/fusion_noop.txt
