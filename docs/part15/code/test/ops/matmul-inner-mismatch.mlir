// A static inner-dimension mismatch is rejected by the verifier.
// RUN: %not %mg-opt %s 2>&1 | %FileCheck %s
// CHECK: error: 'mg.matmul' op mg.matmul inner dimensions differ: 'tensor<2x3xf64>' times 'tensor<2x3xf64>'
func.func @f(%a: tensor<2x3xf64>, %b: tensor<2x3xf64>) -> tensor<2x3xf64> {
  %0 = mg.matmul %a, %b : tensor<2x3xf64>, tensor<2x3xf64> -> tensor<2x3xf64>
  func.return %0 : tensor<2x3xf64>
}
