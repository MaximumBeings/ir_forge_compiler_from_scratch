// Chapter 19: an assert inside a loop, run for real. Clean data finishes; a NaN at index 3 aborts with the message on stderr.
// RUN: %mg-opt %inputs/nested.mlir %lower-with-stderr -o %t.llvm.mlir
// RUN: %mlir-translate --mlir-to-llvmir %t.llvm.mlir -o %t.ll
// RUN: %clang -c %t.ll -o %t.o
// RUN: %clang %inputs/nested_harness.c %t.o -lm -o %t.exe
// RUN: %t.exe | %FileCheck %s --check-prefix=CLEAN
// RUN: %not --crash %t.exe nan
// RUN: %not --crash %t.exe nan 2>&1 >/dev/null | %FileCheck %s --check-prefix=NAN
// CLEAN: survived: no NaN found
// NAN: value is NaN
