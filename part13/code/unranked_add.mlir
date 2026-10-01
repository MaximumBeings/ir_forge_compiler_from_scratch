func.func @u(%a: tensor<*xf64>, %b: tensor<*xf64>) -> tensor<*xf64> {
  %0 = mg.add %a, %b : tensor<*xf64>, tensor<*xf64> -> tensor<*xf64>
  func.return %0 : tensor<*xf64>
}
