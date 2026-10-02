// Chapter 19: the pass may run more than once on a module. First run: the top-level assert is rewritten and the one inside the loop is
// left (guard). After flattening, the second run rewrites it. Both messages get DISTINCT global names. Before the fix the counter
// restarted at zero and the second run failed with `redefinition of symbol named 'mg_assert_stderr_msg_0'`.
// RUN: %mg-opt %inputs/twice.mlir --mg-lower-assert-to-stderr --lower-affine --convert-scf-to-cf --mg-lower-assert-to-stderr | %FileCheck %s
// CHECK-DAG: llvm.mlir.global private constant @mg_assert_stderr_msg_0("top-level check\0A")
// CHECK-DAG: llvm.mlir.global private constant @mg_assert_stderr_msg_1("value is NaN\0A")
// CHECK-NOT: cf.assert
