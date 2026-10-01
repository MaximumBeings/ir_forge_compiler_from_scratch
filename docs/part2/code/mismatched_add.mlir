func.func @main() {
  %0 = mg.constant dense<[[1.0, 2.0], [3.0, 4.0]]> : tensor<2x2xf64>
  %1 = mg.constant dense<[1.0, 2.0, 3.0]> : tensor<3xf64>
  %2 = mg.add %0, %1 : tensor<2x2xf64>, tensor<3xf64> -> tensor<2x2xf64>
  mg.print %2 : tensor<2x2xf64>
  func.return
}
