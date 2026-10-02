// Chapter 19: with the pass in the pipeline, programs that satisfy their assertions are unaffected (eleven runtime shapes).
// RUN: %mg-opt %inputs/chain.mlir --convert-mg-to-affine %lower-with-stderr -o %t.llvm.mlir
// RUN: %mlir-translate --mlir-to-llvmir %t.llvm.mlir -o %t.ll
// RUN: %clang -c %t.ll -o %t.o
// RUN: %clang %inputs/chain_harness.c %t.o -o %t.exe
// RUN: %t.exe | %FileCheck %s
// CHECK-NOT: FAIL
// CHECK: ALL SHAPES PASS
