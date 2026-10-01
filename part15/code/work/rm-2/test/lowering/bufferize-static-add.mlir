// Chapter 6: static One-Shot Bufferize path: no dynamic machinery, no runtime check.
// RUN: %mg-opt %s --one-shot-bufferize="bufferize-function-boundaries" | %FileCheck %s
// CHECK: memref.alloc() : memref<2x2xf64>
// CHECK: affine.for %{{.*}} = 0 to 2
// CHECK-NOT: cf.assert
// CHECK-NOT: memref.dim
func.func @add_tensors(%a: tensor<2x2xf64>, %b: tensor<2x2xf64>) -> tensor<2x2xf64> {
  %0 = mg.add %a, %b : tensor<2x2xf64>, tensor<2x2xf64> -> tensor<2x2xf64>
  func.return %0 : tensor<2x2xf64>
}
