func.func @grad(%x: tensor<?x4xf64>, %y: tensor<?x1xf64>, %p: tensor<4x1xf64>) -> tensor<4x1xf64> {
  %t1 = mg.transpose %x : tensor<?x4xf64> to tensor<4x?xf64>
  %t2 = mg.matmul %x, %p : tensor<?x4xf64>, tensor<4x1xf64> -> tensor<?x1xf64>
  %t3 = mg.sub %t2, %y : tensor<?x1xf64>, tensor<?x1xf64> -> tensor<?x1xf64>
  %t4 = mg.matmul %t1, %t3 : tensor<4x?xf64>, tensor<?x1xf64> -> tensor<4x1xf64>
  func.return %t4 : tensor<4x1xf64>
}
func.func @step(%x: tensor<?x4xf64>, %y: tensor<?x1xf64>, %p: tensor<4x1xf64>, %rate: tensor<1x1xf64>) -> tensor<4x1xf64> {
  %t1 = func.call @grad(%x, %y, %p) : (tensor<?x4xf64>, tensor<?x1xf64>, tensor<4x1xf64>) -> tensor<4x1xf64>
  %t2 = mg.broadcast %rate : tensor<1x1xf64> -> tensor<4x1xf64>
  %t3 = mg.mul %t2, %t1 : tensor<4x1xf64>, tensor<4x1xf64> -> tensor<4x1xf64>
  %t4 = mg.sub %p, %t3 : tensor<4x1xf64>, tensor<4x1xf64> -> tensor<4x1xf64>
  func.return %t4 : tensor<4x1xf64>
}
func.func @loss_sum(%x: tensor<?x4xf64>, %y: tensor<?x1xf64>, %p: tensor<4x1xf64>) -> tensor<1x1xf64> {
  %t1 = mg.matmul %x, %p : tensor<?x4xf64>, tensor<4x1xf64> -> tensor<?x1xf64>
  %t2 = mg.sub %t1, %y : tensor<?x1xf64>, tensor<?x1xf64> -> tensor<?x1xf64>
  %t3 = mg.matmul %x, %p : tensor<?x4xf64>, tensor<4x1xf64> -> tensor<?x1xf64>
  %t4 = mg.sub %t3, %y : tensor<?x1xf64>, tensor<?x1xf64> -> tensor<?x1xf64>
  %t5 = mg.mul %t2, %t4 : tensor<?x1xf64>, tensor<?x1xf64> -> tensor<?x1xf64>
  %t6 = mg.reduce %t5 {axis = 0 : i64, kind = "sum"} : tensor<?x1xf64> -> tensor<1x1xf64>
  func.return %t6 : tensor<1x1xf64>
}
