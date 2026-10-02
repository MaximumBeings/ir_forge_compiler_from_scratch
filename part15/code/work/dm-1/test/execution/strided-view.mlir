// Chapter 13: only the One-Shot Bufferize path's strided argument type honors a column-major view.
// RUN: %mg-opt %inputs/dyn.mlir --one-shot-bufferize="bufferize-function-boundaries" -o %t.b0.mlir
// RUN: %mg-opt %t.b0.mlir %lower-to-llvm -o %t.b.mlir
// RUN: %mlir-translate --mlir-to-llvmir %t.b.mlir -o %t.b.ll
// RUN: %clang -c %t.b.ll -o %t.b.o
// RUN: %clang -DSTRIDED %inputs/dyn_harness.c %t.b.o -o %t.b.exe
// RUN: %t.b.exe | %FileCheck %s
// CHECK-LABEL: transpose 2x3 column-major view -> 3x2:
// CHECK-NEXT: 1 2
// CHECK-NEXT: 3 4
// CHECK-NEXT: 5 6
