func.func @main() {
  %0 = mg.constant dense<[[1.0, 2.0], [3.0, 4.0]]> : tensor<2x2xf64>
  %1 = mg.constant dense<[[5.0, 6.0], [7.0, 8.0]]> : tensor<2x2xf64>
  %2 = mg.add %0, %1 : tensor<2x2xf64>, tensor<2x2xf64> -> tensor<2x2xf64>
  %3 = mg.transpose %2 : tensor<2x2xf64> to tensor<2x2xf64>
  mg.print %3 : tensor<2x2xf64>
  func.return
}
