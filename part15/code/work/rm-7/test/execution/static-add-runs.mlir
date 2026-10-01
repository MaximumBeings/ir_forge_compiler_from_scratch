// Chapter 8: static add, both paths, compiled to a native executable and run.
// RUN: %mg-opt %inputs/static_add.mlir --convert-mg-to-affine %lower-to-llvm -o %t.a.mlir
// RUN: %mlir-translate --mlir-to-llvmir %t.a.mlir -o %t.a.ll
// RUN: %clang -c %t.a.ll -o %t.a.o
// RUN: %clang %inputs/static_harness.c %t.a.o -o %t.a.exe
// RUN: %t.a.exe | %FileCheck %s
// RUN: %mg-opt %inputs/static_add.mlir --one-shot-bufferize="bufferize-function-boundaries" -o %t.b0.mlir
// RUN: %mg-opt %t.b0.mlir %lower-to-llvm -o %t.b.mlir
// RUN: %mlir-translate --mlir-to-llvmir %t.b.mlir -o %t.b.ll
// RUN: %clang -c %t.b.ll -o %t.b.o
// RUN: %clang %inputs/static_harness.c %t.b.o -o %t.b.exe
// RUN: %t.b.exe | %FileCheck %s
// CHECK: 6 8
// CHECK-NEXT: 10 12
// (input program lives in Inputs/static_add.mlir)
