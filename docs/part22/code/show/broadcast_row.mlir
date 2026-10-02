func.func @f(%a: tensor<1x3xf64>) -> tensor<2x3xf64> {
  %0 = mg.broadcast %a : tensor<1x3xf64> -> tensor<2x3xf64>
  func.return %0 : tensor<2x3xf64>
}
