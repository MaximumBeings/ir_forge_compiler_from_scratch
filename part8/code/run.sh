#!/bin/sh
# Chapter 8: the commands this chapter shows, run in order. Intermediate files go to ./work/.
# Needs Chapter 7's mg-opt: run ../part7/code/build.sh first.
HERE=$(cd "$(dirname "$0")" && pwd); cd $HERE; W=$HERE/work; mkdir -p $W
MG=$HERE/../../part7/code/build/mg-opt
echo "--- to affine"; $MG add_tensors.mlir --convert-mg-to-affine
echo "--- the whole pipeline to the llvm dialect"; $MG add_tensors.mlir --convert-mg-to-affine --lower-affine --convert-scf-to-cf --convert-arith-to-llvm --finalize-memref-to-llvm --convert-func-to-llvm --reconcile-unrealized-casts -o $W/add_tensors_llvm.mlir
echo "--- translate, compile, link"; mlir-translate-18 --mlir-to-llvmir $W/add_tensors_llvm.mlir -o $W/add_tensors.ll
clang-18 -c $W/add_tensors.ll -o $W/add_tensors.o; clang-18 -Wall -Wextra -c harness.c -o $W/harness.o; clang-18 $W/add_tensors.o $W/harness.o -o $W/add_tensors_demo
echo "--- run"; $W/add_tensors_demo
echo "--- which shared libraries does it need? (only libc is expected)"; ldd $W/add_tensors_demo
