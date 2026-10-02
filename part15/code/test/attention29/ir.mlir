// Chapter 29: what the stable softmax turns into. Example 4's softmax subtracts the row maximum (a reduce, then a broadcast of the 2x1 result across
// the columns), exponentiates, sums each row, and divides (the sum is broadcast the same way).
// RUN: %mgc29 mlir %ex29/04_softmax_stable.mg | %FileCheck %s
// CHECK: mg.reduce {{.*}}kind = "max"{{.*}} : tensor<2x3xf64> -> tensor<2x1xf64>
// CHECK: mg.broadcast {{.*}} : tensor<2x1xf64> -> tensor<2x3xf64>
// CHECK: mg.sub {{.*}} : tensor<2x3xf64>, tensor<2x3xf64> -> tensor<2x3xf64>
// CHECK: mg.exp {{.*}} : tensor<2x3xf64> -> tensor<2x3xf64>
// CHECK: mg.reduce {{.*}}kind = "sum"{{.*}} : tensor<2x3xf64> -> tensor<2x1xf64>
// CHECK: mg.div {{.*}} : tensor<2x3xf64>, tensor<2x3xf64> -> tensor<2x3xf64>
