func.func @add_tensors(%a: tensor<2x2xf64>, %b: tensor<2x2xf64>) -> tensor<2x2xf64> {
  %0 = mg.add %a, %b : tensor<2x2xf64>, tensor<2x2xf64> -> tensor<2x2xf64>
  func.return %0 : tensor<2x2xf64>
}
