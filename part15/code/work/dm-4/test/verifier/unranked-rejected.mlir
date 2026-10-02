// Chapter 13: an explicit diagnostic instead of an unchecked cast.
// RUN: %not %mg-opt %s 2>&1 | %FileCheck %s
// CHECK: error: 'mg.transpose' op mg.transpose only supports ranked tensors
func.func @f(%a: tensor<*xf64>) -> tensor<*xf64> {
  %0 = mg.transpose %a : tensor<*xf64> to tensor<*xf64>
  func.return %0 : tensor<*xf64>
}
