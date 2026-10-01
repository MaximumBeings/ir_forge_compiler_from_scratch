// RUN: %not %mg-opt %s 2>&1 | %FileCheck %s
// CHECK: error: 'mg.transpose' op mg.transpose only supports rank-2 tensors
func.func @f(%a: tensor<2x2x2xf64>) -> tensor<2x2x2xf64> {
  %0 = mg.transpose %a : tensor<2x2x2xf64> to tensor<2x2x2xf64>
  func.return %0 : tensor<2x2x2xf64>
}
