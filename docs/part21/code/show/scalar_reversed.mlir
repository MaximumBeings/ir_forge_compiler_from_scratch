func.func @f(%a: tensor<2x2xf64>) -> tensor<2x2xf64> {
  %0 = mg.scalar %a {op = "sub", value = 10.0 : f64, reversed = true} : tensor<2x2xf64> -> tensor<2x2xf64>
  func.return %0 : tensor<2x2xf64>
}
