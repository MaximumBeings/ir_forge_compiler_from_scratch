#!/bin/sh
# Chapter 5: the commands this chapter shows, run in order. Intermediate files go to ./work/.
# Needs ./build.sh first, and the MLIR runner libraries (libmlir_runner_utils.so, libmlir_c_runner_utils.so).
HERE=$(cd "$(dirname "$0")" && pwd); cd $HERE; W=$HERE/work; mkdir -p $W
MG=$HERE/build/mg-opt
echo "--- to affine and scf"; $MG mountain_goat_run.mlir --convert-mg-to-affine --lower-affine
echo "--- the whole pipeline to the llvm dialect"
$MG mountain_goat_run.mlir --convert-mg-to-affine --lower-affine --convert-scf-to-cf --convert-arith-to-llvm --finalize-memref-to-llvm --convert-func-to-llvm --reconcile-unrealized-casts -o $W/mountain_goat_llvm.mlir
echo "--- run it with MLIR's JIT"
mlir-cpu-runner-18 $W/mountain_goat_llvm.mlir --shared-libs=/usr/lib/llvm-18/lib/libmlir_runner_utils.so --shared-libs=/usr/lib/llvm-18/lib/libmlir_c_runner_utils.so -e main -entry-point-result=void
