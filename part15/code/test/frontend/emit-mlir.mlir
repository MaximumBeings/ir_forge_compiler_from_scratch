// Chapter 20: what the front end produces for a small program (typed mg ops, dynamic call via tensor.cast).
// RUN: %mgc mlir %ex/03_dynamic.mg | %FileCheck %s
// CHECK-LABEL: func.func @addt(%a: tensor<?x?xf64>, %b: tensor<?x?xf64>) -> tensor<?x?xf64>
// CHECK: mg.add %a, %b : tensor<?x?xf64>, tensor<?x?xf64> -> tensor<?x?xf64>
// CHECK: mg.transpose {{.*}} : tensor<?x?xf64> to tensor<?x?xf64>
// CHECK-LABEL: func.func @main() -> i32
// CHECK: mg.constant dense<{{.*}}> : tensor<2x3xf64>
// CHECK: tensor.cast {{.*}} : tensor<2x3xf64> to tensor<?x?xf64>
// CHECK: func.call @addt
