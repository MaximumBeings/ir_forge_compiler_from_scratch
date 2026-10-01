func.func @add_tensors(%a: tensor<2x2xf64>, %b: tensor<2x2xf64>) {
  %0 = mg.add %a, %b : tensor<2x2xf64>, tensor<2x2xf64> -> tensor<2x2xf64>
  mg.print %0 : tensor<2x2xf64>
  func.return
}

func.func @main() {
  %0 = mg.constant dense<[[1.0, 2.0], [3.0, 4.0]]> : tensor<2x2xf64>
  %1 = mg.constant dense<[[5.0, 6.0], [7.0, 8.0]]> : tensor<2x2xf64>
  func.call @add_tensors(%0, %1) : (tensor<2x2xf64>, tensor<2x2xf64>) -> ()
  func.return
}
