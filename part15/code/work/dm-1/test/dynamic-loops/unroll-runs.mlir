// Chapter 17: partial unrolling (factor 4) of a dynamic-bound nest stays correct on eleven shapes, remainders included.
// RUN: %mg-opt %inputs/chain.mlir --convert-mg-to-affine -o %t.affine.mlir
// RUN: %mg-opt %t.affine.mlir --affine-loop-unroll="unroll-factor=4" -o %t.unrolled.mlir
// RUN: %mg-opt %t.unrolled.mlir %lower-to-llvm -o %t.llvm.mlir
// RUN: %mlir-translate --mlir-to-llvmir %t.llvm.mlir -o %t.ll
// RUN: %clang -c %t.ll -o %t.o
// RUN: %clang %inputs/chain_harness.c %t.o -o %t.exe
// RUN: %t.exe | %FileCheck %s
// CHECK-NOT: FAIL
// CHECK: ALL SHAPES PASS
