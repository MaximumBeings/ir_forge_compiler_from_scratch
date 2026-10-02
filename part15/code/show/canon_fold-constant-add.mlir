module {
  func.func @main() {
    %0 = mg.constant dense<[[6.000000e+00, 8.000000e+00], [1.000000e+01, 1.200000e+01]]> : tensor<2x2xf64>
    mg.print %0 : tensor<2x2xf64>
    return
  }
}

