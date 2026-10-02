module {
  func.func @dyn(%arg0: tensor<?x?xf64>, %arg1: tensor<?x?xf64>) -> tensor<?x?xf64> {
    %0 = mg.add %arg0, %arg1 : tensor<?x?xf64>, tensor<?x?xf64> -> tensor<?x?xf64>
    return %0 : tensor<?x?xf64>
  }
  func.func @mixed(%arg0: tensor<?x2xf64>, %arg1: tensor<3x2xf64>) -> tensor<?x2xf64> {
    %0 = mg.add %arg0, %arg1 : tensor<?x2xf64>, tensor<3x2xf64> -> tensor<?x2xf64>
    return %0 : tensor<?x2xf64>
  }
  func.func @t(%arg0: tensor<?x?xf64>) -> tensor<?x?xf64> {
    %0 = mg.transpose %arg0 : tensor<?x?xf64> to tensor<?x?xf64>
    return %0 : tensor<?x?xf64>
  }
}

