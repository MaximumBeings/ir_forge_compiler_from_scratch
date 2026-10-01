func.func @add_dyn(%a: tensor<?x?xf64>, %b: tensor<?x?xf64>) -> tensor<?x?xf64> {
  %0 = mg.add %a, %b : tensor<?x?xf64>, tensor<?x?xf64> -> tensor<?x?xf64>
  func.return %0 : tensor<?x?xf64>
}
