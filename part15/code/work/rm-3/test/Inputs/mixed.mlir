func.func @mixed(%a: tensor<?x2xf64>, %b: tensor<3x2xf64>) -> tensor<?x2xf64> {
  %0 = mg.add %a, %b : tensor<?x2xf64>, tensor<3x2xf64> -> tensor<?x2xf64>
  func.return %0 : tensor<?x2xf64>
}
