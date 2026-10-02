func.func @chain(%a: tensor<4x6xf64>, %b: tensor<4x6xf64>) -> tensor<6x4xf64> {
  %s = mg.add %a, %b : tensor<4x6xf64>, tensor<4x6xf64> -> tensor<4x6xf64>
  %t = mg.transpose %s : tensor<4x6xf64> to tensor<6x4xf64>
  func.return %t : tensor<6x4xf64>
}
