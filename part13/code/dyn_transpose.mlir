func.func @t_dyn(%a: tensor<?x?xf64>) -> tensor<?x?xf64> {
  %0 = mg.transpose %a : tensor<?x?xf64> to tensor<?x?xf64>
  func.return %0 : tensor<?x?xf64>
}
