// Chapter 19: --mg-lower-assert-to-stderr turns every cf.assert in a function body into a branch whose failing side write()s the
// message to file descriptor 2 and aborts. No cf.assert is left; the two messages become two private constant strings.
// RUN: %mg-opt %inputs/dyn.mlir --convert-mg-to-affine --mg-lower-assert-to-stderr | %FileCheck %s
// CHECK-DAG: llvm.mlir.global private constant @mg_assert_stderr_msg_{{[0-9]+}}("mg.add: operand shapes differ at runtime in dimension 0\0A")
// CHECK-DAG: llvm.mlir.global private constant @mg_assert_stderr_msg_{{[0-9]+}}("mg.add: operand shapes differ at runtime in dimension 1\0A")
// CHECK-DAG: llvm.func @write(i32, !llvm.ptr, i64) -> i64
// CHECK-DAG: llvm.func @abort()
// CHECK-NOT: cf.assert
// CHECK: cf.cond_br
// CHECK: llvm.call @write(%{{.*}}, %{{.*}}, %{{.*}}) : (i32, !llvm.ptr, i64) -> i64
// CHECK-NEXT: llvm.call @abort() : () -> ()
// CHECK-NEXT: llvm.unreachable
