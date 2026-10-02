// Chapter 17: Chapter 14's runtime shape check must survive tiling and unrolling: a mismatched call still ABORTS.
// RUN: %mg-opt %inputs/chain.mlir --convert-mg-to-affine -o %t.affine.mlir
// RUN: %mg-opt %t.affine.mlir --affine-loop-tile="tile-size=4" --affine-loop-unroll="unroll-factor=2" -o %t.xf.mlir
// RUN: %mg-opt %t.xf.mlir %lower-to-llvm -o %t.llvm.mlir
// RUN: %mlir-translate --mlir-to-llvmir %t.llvm.mlir -o %t.ll
// RUN: %clang -c %t.ll -o %t.o
// RUN: %clang %inputs/chain_mismatch_harness.c %t.o -o %t.exe
// RUN: %not --crash %t.exe
// RUN: %not --crash stdbuf -oL %t.exe 2>&1 | %FileCheck %s
// CHECK: mg.add: operand shapes differ at runtime in dimension 0
