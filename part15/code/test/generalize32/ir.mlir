// Chapter 32: what ge turns into. The first print compares two 2x3 matrices directly; the second stretches a 2x1 column across the columns first
// (an explicit mg.broadcast, Chapter 22) and then compares.
// RUN: %mgc32 mlir %ex32/01_ge.mg | %FileCheck %s
// CHECK: mg.ge {{.*}} : tensor<2x3xf64>, tensor<2x3xf64> -> tensor<2x3xf64>
// CHECK: mg.broadcast {{.*}} : tensor<2x1xf64> -> tensor<2x3xf64>
// CHECK: mg.ge {{.*}} : tensor<2x3xf64>, tensor<2x3xf64> -> tensor<2x3xf64>
