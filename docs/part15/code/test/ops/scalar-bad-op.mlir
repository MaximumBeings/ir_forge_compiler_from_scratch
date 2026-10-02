// mg.scalar accepts only add, sub, mul, div.
// RUN: %not %mg-opt %s 2>&1 | %FileCheck %s
// CHECK: error: 'mg.scalar' op mg.scalar: op must be one of add, sub, mul, div, got 'pow'
func.func @f(%a: tensor<2x2xf64>) -> tensor<2x2xf64> {
  %0 = mg.scalar %a {op = "pow", value = 2.0 : f64, reversed = false} : tensor<2x2xf64> -> tensor<2x2xf64>
  func.return %0 : tensor<2x2xf64>
}
