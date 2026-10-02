func.func @f(%a: tensor<2x3xf64>) -> tensor<2x1xf64> {
  %0 = mg.reduce %a {axis = 1 : i64, kind = "sum"} : tensor<2x3xf64> -> tensor<2x1xf64>
  func.return %0 : tensor<2x1xf64>
}
