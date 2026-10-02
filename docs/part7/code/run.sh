#!/bin/sh
# Chapter 7: the commands this chapter shows, run in order. Intermediate files go to ./work/.
# Needs ./build.sh first, and the MLIR runner libraries.
HERE=$(cd "$(dirname "$0")" && pwd); cd $HERE; W=$HERE/work; mkdir -p $W
MG=$HERE/build/mg-opt
echo "--- lower mountain_goat_src.mlir to affine"; $MG mountain_goat_src.mlir --convert-mg-to-affine
echo "--- fusion"; $MG mountain_goat_affine.mlir --affine-loop-fusion
echo "--- tiling (tile size 1)"; $MG mountain_goat_fused.mlir --affine-loop-tile="tile-size=1"
echo "--- unrolling"; $MG mountain_goat_fused.mlir --affine-loop-unroll="unroll-full" --affine-loop-unroll="unroll-full"
echo "--- unrolling, then canonicalize"; $MG mountain_goat_fused.mlir --affine-loop-unroll="unroll-full" --affine-loop-unroll="unroll-full" --canonicalize
echo "--- everything, then run"
$MG mountain_goat_full.mlir --convert-mg-to-affine --affine-loop-fusion --affine-loop-tile="tile-size=1" --affine-loop-unroll="unroll-full" --affine-loop-unroll="unroll-full" --affine-loop-unroll="unroll-full" --canonicalize --lower-affine --convert-scf-to-cf --convert-arith-to-llvm --finalize-memref-to-llvm --convert-func-to-llvm --reconcile-unrealized-casts -o $W/full_llvm.mlir
mlir-cpu-runner-18 $W/full_llvm.mlir --shared-libs=/usr/lib/llvm-18/lib/libmlir_runner_utils.so --shared-libs=/usr/lib/llvm-18/lib/libmlir_c_runner_utils.so -e main -entry-point-result=void
