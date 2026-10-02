func.func @chain2(%a: tensor<?x2xf64>, %b: tensor<?x2xf64>) -> tensor<2x?xf64> {
  %s = mg.add %a, %b : tensor<?x2xf64>, tensor<?x2xf64> -> tensor<?x2xf64>
  %t = mg.transpose %s : tensor<?x2xf64> to tensor<2x?xf64>
  func.return %t : tensor<2x?xf64>
}
