// Chapter 14: a runtime shape mismatch must abort (SIGABRT), on both paths, and never return a result.
// RUN: %mg-opt %inputs/dyn.mlir --convert-mg-to-affine %lower-to-llvm -o %t.a.mlir
// RUN: %mlir-translate --mlir-to-llvmir %t.a.mlir -o %t.a.ll
// RUN: %clang -c %t.a.ll -o %t.a.o
// RUN: %clang %inputs/mismatch_harness.c %t.a.o -o %t.a.exe
// RUN: %not --crash %t.a.exe
// RUN: %mg-opt %inputs/dyn.mlir --one-shot-bufferize="bufferize-function-boundaries" -o %t.b0.mlir
// RUN: %mg-opt %t.b0.mlir %lower-to-llvm -o %t.b.mlir
// RUN: %mlir-translate --mlir-to-llvmir %t.b.mlir -o %t.b.ll
// RUN: %clang -c %t.b.ll -o %t.b.o
// RUN: %clang %inputs/mismatch_harness.c %t.b.o -o %t.b.exe
// RUN: %not --crash %t.b.exe
// The message goes to stdout (puts) and abort() does not flush it, so only a line-buffered run shows it:
// RUN: %not --crash stdbuf -oL %t.a.exe 2>&1 | %FileCheck %s
// CHECK: mg.add: operand shapes differ at runtime in dimension 0
