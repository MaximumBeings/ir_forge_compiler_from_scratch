func.func @u(%a: tensor<*xf64>) -> tensor<*xf64> {
  %0 = mg.transpose %a : tensor<*xf64> to tensor<*xf64>
  func.return %0 : tensor<*xf64>
}
