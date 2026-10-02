// Chapter 30: what layer normalisation turns into: subtract the row mean, square, take the row mean, add epsilon, sqrt, divide, scale, shift.
// RUN: %mgc30 mlir %ex30/01_layer_norm.mg | %FileCheck %s
// CHECK: mg.reduce {{.*}}kind = "sum"{{.*}} : tensor<4x4xf64> -> tensor<4x1xf64>
// CHECK: mg.sub {{.*}} : tensor<4x4xf64>, tensor<4x4xf64> -> tensor<4x4xf64>
// CHECK: mg.mul {{.*}} : tensor<4x4xf64>, tensor<4x4xf64> -> tensor<4x4xf64>
// CHECK: mg.sqrt {{.*}} : tensor<4x1xf64> -> tensor<4x1xf64>
// CHECK: mg.div {{.*}} : tensor<4x4xf64>, tensor<4x4xf64> -> tensor<4x4xf64>
// CHECK: mg.mul {{.*}} : tensor<4x4xf64>, tensor<4x4xf64> -> tensor<4x4xf64>
// CHECK: mg.add {{.*}} : tensor<4x4xf64>, tensor<4x4xf64> -> tensor<4x4xf64>
