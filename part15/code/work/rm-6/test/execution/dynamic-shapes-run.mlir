// Chapters 13/14: ONE compiled function handles several non-square shapes, on both lowering paths.
// RUN: %mg-opt %inputs/dyn.mlir --convert-mg-to-affine %lower-to-llvm -o %t.a.mlir
// RUN: %mlir-translate --mlir-to-llvmir %t.a.mlir -o %t.a.ll
// RUN: %clang -c %t.a.ll -o %t.a.o
// RUN: %clang %inputs/dyn_harness.c %t.a.o -o %t.a.exe
// RUN: %t.a.exe | %FileCheck %s
// RUN: %mg-opt %inputs/dyn.mlir --one-shot-bufferize="bufferize-function-boundaries" -o %t.b0.mlir
// RUN: %mg-opt %t.b0.mlir %lower-to-llvm -o %t.b.mlir
// RUN: %mlir-translate --mlir-to-llvmir %t.b.mlir -o %t.b.ll
// RUN: %clang -c %t.b.ll -o %t.b.o
// RUN: %clang %inputs/dyn_harness.c %t.b.o -o %t.b.exe
// RUN: %t.b.exe | %FileCheck %s
// CHECK-LABEL: add 2x3 -> 2x3:
// CHECK-NEXT: 11 22 33
// CHECK-NEXT: 44 55 66
// CHECK-LABEL: add 3x2 -> 3x2:
// CHECK-NEXT: 11 22
// CHECK-NEXT: 33 44
// CHECK-NEXT: 55 66
// CHECK-LABEL: add 1x6 -> 1x6:
// CHECK-NEXT: 11 22 33 44 55 66
// CHECK-LABEL: transpose 2x3 -> 3x2:
// CHECK-NEXT: 1 4
// CHECK-NEXT: 2 5
// CHECK-NEXT: 3 6
// CHECK-LABEL: transpose 1x6 -> 6x1:
// CHECK-NEXT: 1
// CHECK-NEXT: 2
// CHECK-NEXT: 3
// CHECK-NEXT: 4
// CHECK-NEXT: 5
// CHECK-NEXT: 6
