// Chapter 31: what the stable log-softmax turns into: subtract the row maximum, exponentiate, sum each row, mg.log of the 4x1 sums, subtract.
// RUN: %mgc31 mlir %ex31/03_one_gradient_step.mg | %FileCheck %s
// CHECK: mg.reduce {{.*}}kind = "max"{{.*}} : tensor<4x2xf64> -> tensor<4x1xf64>
// CHECK: mg.exp {{.*}} : tensor<4x2xf64> -> tensor<4x2xf64>
// CHECK: mg.reduce {{.*}}kind = "sum"{{.*}} : tensor<4x2xf64> -> tensor<4x1xf64>
// CHECK: mg.log {{.*}} : tensor<4x1xf64> -> tensor<4x1xf64>
