// An unknown loop order is an error with a clear message, not a silent fallback.
// RUN: %not %mg-opt %s --convert-mg-to-affine=matmul-order=jki 2>&1 | %FileCheck %s
// CHECK: error: convert-mg-to-affine: matmul-order must be ijk or ikj, got 'jki'
func.func @mm(%a: tensor<2x3xf64>, %b: tensor<3x4xf64>) -> tensor<2x4xf64> {
  %0 = mg.matmul %a, %b : tensor<2x3xf64>, tensor<3x4xf64> -> tensor<2x4xf64>
  func.return %0 : tensor<2x4xf64>
}
