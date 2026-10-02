// Chapter 17: tiling a DYNAMIC-bound nest (tile size 4) stays correct on eleven runtime shapes, including ones that do not divide 4.
// RUN: %mg-opt %inputs/chain.mlir --convert-mg-to-affine -o %t.affine.mlir
// RUN: %mg-opt %t.affine.mlir --affine-loop-tile="tile-size=4" -o %t.tiled.mlir
// RUN: %mg-opt %t.tiled.mlir %lower-to-llvm -o %t.llvm.mlir
// RUN: %mlir-translate --mlir-to-llvmir %t.llvm.mlir -o %t.ll
// RUN: %clang -c %t.ll -o %t.o
// RUN: %clang %inputs/chain_harness.c %t.o -o %t.exe
// RUN: %t.exe | %FileCheck %s
// CHECK-NOT: FAIL
// CHECK: ALL SHAPES PASS
