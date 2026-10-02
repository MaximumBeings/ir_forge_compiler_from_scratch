// Chapter 14: ?x2 + 3x2: matching sizes work, mismatched sizes abort.
// RUN: %mg-opt %inputs/mixed.mlir --convert-mg-to-affine %lower-to-llvm -o %t.m.mlir
// RUN: %mlir-translate --mlir-to-llvmir %t.m.mlir -o %t.m.ll
// RUN: %clang -c %t.m.ll -o %t.m.o
// RUN: %clang %inputs/mixed_harness.c %t.m.o -o %t.m.exe
// RUN: %t.m.exe 3 | %FileCheck %s
// RUN: %not --crash %t.m.exe 2
// CHECK: mixed with a=3x2, b=3x2 -> 3x2: 11 22 33 44 55 66
