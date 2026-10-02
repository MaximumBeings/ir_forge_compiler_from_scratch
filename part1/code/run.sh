#!/bin/sh
# Chapter 1: the commands this chapter shows, run in order. Intermediate files go to ./work/.
# Needs: clang-18, mlir-opt-18, mlir-translate-18 (see Getting Started). No build step.
HERE=$(cd "$(dirname "$0")" && pwd); cd $HERE; W=$HERE/work; mkdir -p $W
echo "--- mlir-opt-18 sum.mlir  (parse, verify, print)"; mlir-opt-18 sum.mlir
echo "--- lower to the llvm dialect"; mlir-opt-18 sum.mlir --convert-scf-to-cf --convert-arith-to-llvm --finalize-memref-to-llvm --convert-func-to-llvm --reconcile-unrealized-casts -o $W/sum_llvm.mlir
echo "--- translate to LLVM IR"; mlir-translate-18 --mlir-to-llvmir $W/sum_llvm.mlir -o $W/sum.ll
echo "--- compile and link"; clang-18 -c $W/sum.ll -o $W/sum.o; clang-18 -Wall -Wextra -c harness.c -o $W/harness.o; clang-18 $W/sum.o $W/harness.o -o $W/sum_demo
echo "--- run"; $W/sum_demo
