// Chapter 4/5: static mg.add -> affine loop nest with constant bounds, and NO runtime checks.
// RUN: %mg-opt %s --convert-mg-to-affine | %FileCheck %s
// CHECK: memref.alloc() : memref<2x2xf64>
// CHECK: affine.for %{{.*}} = 0 to 2 {
// CHECK: affine.for %{{.*}} = 0 to 2 {
// CHECK: affine.load
// CHECK: affine.load
// CHECK: arith.addf
// CHECK: affine.store
// CHECK-NOT: cf.assert
// CHECK-NOT: memref.dim
func.func @add_tensors(%a: tensor<2x2xf64>, %b: tensor<2x2xf64>) -> tensor<2x2xf64> {
  %0 = mg.add %a, %b : tensor<2x2xf64>, tensor<2x2xf64> -> tensor<2x2xf64>
  func.return %0 : tensor<2x2xf64>
}
