#!/bin/sh
# Chapter 9: the commands this chapter shows, run in order. Intermediate files go to ./work/.
# Needs: cmake, make, llvm-18-dev, libmlir-18-dev, and Chapter 8's lowered IR (add_tensors_llvm.mlir, in this directory).
HERE=$(cd "$(dirname "$0")" && pwd); cd $HERE; W=$HERE/work; mkdir -p $W
cmake -S . -B $W/build -DMLIR_DIR=/usr/lib/llvm-18/lib/cmake/mlir -DLLVM_DIR=/usr/lib/llvm-18/lib/cmake/llvm -DCMAKE_BUILD_TYPE=Release > $W/cmake_out.txt 2>&1
cmake --build $W/build -j4 2>&1 | tail -2
echo "--- run_engine add_tensors_llvm.mlir"; $W/build/run_engine add_tensors_llvm.mlir
