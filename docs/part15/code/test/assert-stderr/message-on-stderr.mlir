// Chapter 19: the reason this pass exists. A runtime shape mismatch aborts, AND its message reaches STDERR even though stdout is
// discarded (Chapter 14 found the default lowering loses the message whenever stdout is not a terminal). Both lowering paths.
// RUN: %mg-opt %inputs/dyn.mlir --convert-mg-to-affine %lower-with-stderr -o %t.a.mlir
// RUN: %mlir-translate --mlir-to-llvmir %t.a.mlir -o %t.a.ll
// RUN: %clang -c %t.a.ll -o %t.a.o
// RUN: %clang %inputs/mismatch_harness.c %t.a.o -o %t.a.exe
// RUN: %not --crash %t.a.exe
// RUN: %not --crash %t.a.exe 2>&1 >/dev/null | %FileCheck %s
// RUN: %mg-opt %inputs/dyn.mlir --one-shot-bufferize="bufferize-function-boundaries" -o %t.b0.mlir
// RUN: %mg-opt %t.b0.mlir %lower-with-stderr -o %t.b.mlir
// RUN: %mlir-translate --mlir-to-llvmir %t.b.mlir -o %t.b.ll
// RUN: %clang -c %t.b.ll -o %t.b.o
// RUN: %clang %inputs/mismatch_harness.c %t.b.o -o %t.b.exe
// RUN: %not --crash %t.b.exe
// RUN: %not --crash %t.b.exe 2>&1 >/dev/null | %FileCheck %s
// CHECK: mg.add: operand shapes differ at runtime in dimension 0
