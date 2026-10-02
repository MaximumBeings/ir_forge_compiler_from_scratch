// sub, mul and div reject static mismatches exactly as add does.
// RUN: %not %mg-opt %s --split-input-file 2>&1 | %FileCheck %s
// CHECK-DAG: error: 'mg.sub' op mg.sub operands must have compatible shapes
// CHECK-DAG: error: 'mg.mul' op mg.mul operands must have compatible shapes
// CHECK-DAG: error: 'mg.div' op mg.div operands must have compatible shapes
func.func @f(%a: tensor<2x2xf64>, %b: tensor<2x3xf64>) -> tensor<2x2xf64> {
  %0 = mg.sub %a, %b : tensor<2x2xf64>, tensor<2x3xf64> -> tensor<2x2xf64>
  func.return %0 : tensor<2x2xf64>
}
// -----
func.func @g(%a: tensor<2x2xf64>, %b: tensor<2x3xf64>) -> tensor<2x2xf64> {
  %1 = mg.mul %a, %b : tensor<2x2xf64>, tensor<2x3xf64> -> tensor<2x2xf64>
  func.return %1 : tensor<2x2xf64>
}
// -----
func.func @h(%a: tensor<2x2xf64>, %b: tensor<2x3xf64>) -> tensor<2x2xf64> {
  %2 = mg.div %a, %b : tensor<2x2xf64>, tensor<2x3xf64> -> tensor<2x2xf64>
  func.return %2 : tensor<2x2xf64>
}
