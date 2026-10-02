module {
  func.func @tt(%arg0: tensor<?x2xf64>) -> tensor<?x?xf64> {
    %0 = mg.transpose %arg0 : tensor<?x2xf64> to tensor<2x?xf64>
    %1 = mg.transpose %0 : tensor<2x?xf64> to tensor<?x?xf64>
    return %1 : tensor<?x?xf64>
  }
}

