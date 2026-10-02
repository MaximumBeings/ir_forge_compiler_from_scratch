// The result of (2x3)@(3x4) must be 2x4, not 2x3.
// RUN: %not %mg-opt %s 2>&1 | %FileCheck %s
// CHECK: error: 'mg.matmul' op mg.matmul result shape must be (rows of lhs) x (columns of rhs), got 'tensor<2x3xf64>'
func.func @f(%a: tensor<2x3xf64>, %b: tensor<3x4xf64>) -> tensor<2x3xf64> {
  %0 = mg.matmul %a, %b : tensor<2x3xf64>, tensor<3x4xf64> -> tensor<2x3xf64>
  func.return %0 : tensor<2x3xf64>
}
