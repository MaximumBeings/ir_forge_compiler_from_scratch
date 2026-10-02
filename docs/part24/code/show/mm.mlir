func.func @mm(%a: tensor<2x3xf64>, %b: tensor<3x4xf64>) -> tensor<2x4xf64> {
  %0 = mg.matmul %a, %b : tensor<2x3xf64>, tensor<3x4xf64> -> tensor<2x4xf64>
  func.return %0 : tensor<2x4xf64>
}
