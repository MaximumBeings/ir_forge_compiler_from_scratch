// RUN: %not %mg-opt %s 2>&1 | %FileCheck %s
// CHECK: error: 'mg.transpose' op mg.transpose result shape must be the input shape reversed
func.func @f(%a: tensor<2x3xf64>) -> tensor<2x3xf64> {
  %0 = mg.transpose %a : tensor<2x3xf64> to tensor<2x3xf64>
  func.return %0 : tensor<2x3xf64>
}
