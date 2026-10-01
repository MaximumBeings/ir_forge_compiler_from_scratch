func.func @compute(%a: tensor<2x2xf64>, %b: tensor<2x2xf64>) {
  %0 = mg.add %a, %b : tensor<2x2xf64>, tensor<2x2xf64> -> tensor<2x2xf64>
  %1 = mg.transpose %0 : tensor<2x2xf64> to tensor<2x2xf64>
  mg.print %1 : tensor<2x2xf64>
  func.return
}
