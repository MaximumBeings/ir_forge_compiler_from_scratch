// A static shape mismatch must be rejected by the verifier, not at runtime.
// RUN: %not %mg-opt %s 2>&1 | %FileCheck %s
// CHECK: error: 'mg.add' op mg.add operands must have compatible shapes, got 'tensor<2x2xf64>' and 'tensor<2x3xf64>'
func.func @f(%a: tensor<2x2xf64>, %b: tensor<2x3xf64>) -> tensor<2x2xf64> {
  %0 = mg.add %a, %b : tensor<2x2xf64>, tensor<2x3xf64> -> tensor<2x2xf64>
  func.return %0 : tensor<2x2xf64>
}
