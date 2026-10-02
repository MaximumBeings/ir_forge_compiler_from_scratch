#!/bin/sh
# Chapter 6: the commands this chapter shows, run in order. Intermediate files go to ./work/.
# Needs ./build.sh first, and the MLIR runner libraries.
HERE=$(cd "$(dirname "$0")" && pwd); cd $HERE; W=$HERE/work; mkdir -p $W
MG=$HERE/build/mg-opt
echo "--- mountain_goat_const.mlir --one-shot-bufferize"; $MG mountain_goat_const.mlir --one-shot-bufferize
echo "--- mountain_goat_run.mlir --one-shot-bufferize=bufferize-function-boundaries"; $MG mountain_goat_run.mlir --one-shot-bufferize="bufferize-function-boundaries"
echo "--- the whole pipeline to the llvm dialect, then JIT"
$MG mountain_goat_run.mlir --one-shot-bufferize="bufferize-function-boundaries" --lower-affine --convert-scf-to-cf --convert-arith-to-llvm --finalize-memref-to-llvm --convert-func-to-llvm --reconcile-unrealized-casts -o $W/mountain_goat_llvm.mlir
mlir-cpu-runner-18 $W/mountain_goat_llvm.mlir --shared-libs=/usr/lib/llvm-18/lib/libmlir_runner_utils.so --shared-libs=/usr/lib/llvm-18/lib/libmlir_c_runner_utils.so -e main -entry-point-result=void
