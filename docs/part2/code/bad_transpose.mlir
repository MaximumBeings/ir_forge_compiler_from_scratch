func.func @main() {
  %0 = mg.constant dense<[[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]]> : tensor<2x3xf64>
  %1 = mg.transpose %0 : tensor<2x3xf64> to tensor<2x3xf64>
  mg.print %1 : tensor<2x3xf64>
  func.return
}
