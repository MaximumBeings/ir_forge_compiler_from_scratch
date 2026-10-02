// Chapter 19: the message is written byte for byte: an embedded quote, a percent sign, and non-ASCII (UTF-8) text, with exactly one
// trailing newline and nothing else on stderr.
// RUN: %mg-opt %inputs/boom.mlir %lower-with-stderr -o %t.llvm.mlir
// RUN: %mlir-translate --mlir-to-llvmir %t.llvm.mlir -o %t.ll
// RUN: %clang -c %t.ll -o %t.o
// RUN: %clang %inputs/boom_harness.c %t.o -o %t.exe
// RUN: %not --crash %t.exe 2>&1 >/dev/null | %FileCheck %s --match-full-lines --strict-whitespace
// CHECK:bad "quote" 100% done, naïve café
