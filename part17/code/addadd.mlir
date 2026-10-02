func.func @addadd(%a: tensor<?x?xf64>, %b: tensor<?x?xf64>, %c: tensor<?x?xf64>) -> tensor<?x?xf64> {
  %s = mg.add %a, %b : tensor<?x?xf64>, tensor<?x?xf64> -> tensor<?x?xf64>
  %t = mg.add %s, %c : tensor<?x?xf64>, tensor<?x?xf64> -> tensor<?x?xf64>
  func.return %t : tensor<?x?xf64>
}
