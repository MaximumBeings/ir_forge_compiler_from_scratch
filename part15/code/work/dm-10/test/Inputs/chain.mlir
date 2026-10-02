func.func @chain(%a: tensor<?x?xf64>, %b: tensor<?x?xf64>) -> tensor<?x?xf64> {
  %s = mg.add %a, %b : tensor<?x?xf64>, tensor<?x?xf64> -> tensor<?x?xf64>
  %t = mg.transpose %s : tensor<?x?xf64> to tensor<?x?xf64>
  func.return %t : tensor<?x?xf64>
}
