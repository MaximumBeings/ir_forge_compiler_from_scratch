// Chapter 1's whole pipeline, from the chapter's own files: parse and verify sum.mlir, lower it to the llvm dialect, translate to
// LLVM IR, compile with the chapter's harness, run. (Chapter 1 had no automated test before; this is the one recorded run, repeated.)
// RUN: %mlir-opt %docs/part1/code/sum.mlir | %FileCheck %s --check-prefix=PARSED
// RUN: %mlir-opt %docs/part1/code/sum.mlir --convert-scf-to-cf --convert-arith-to-llvm --finalize-memref-to-llvm --convert-func-to-llvm --reconcile-unrealized-casts -o %t.llvm.mlir
// RUN: %FileCheck %s --input-file=%t.llvm.mlir --check-prefix=LOWERED
// RUN: %mlir-translate --mlir-to-llvmir %t.llvm.mlir -o %t.ll
// RUN: %clang -c %t.ll -o %t.o
// RUN: %clang %docs/part1/code/harness.c %t.o -o %t.exe
// RUN: %t.exe | %FileCheck %s --check-prefix=SUM
// The structured loop is there after parsing...
// PARSED: scf.for
// PARSED: memref<5xi32>
// ...and gone after lowering: branches, and the single memref argument became five scalars.
// LOWERED-NOT: scf.for
// LOWERED: llvm.func @sum_array(%arg0: !llvm.ptr, %arg1: !llvm.ptr, %arg2: i64, %arg3: i64, %arg4: i64)
// LOWERED: llvm.cond_br
// SUM: sum_array({1,2,3,4,5}) = 15
