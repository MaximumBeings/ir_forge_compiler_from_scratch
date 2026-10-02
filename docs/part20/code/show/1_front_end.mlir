func.func @addt(%a: tensor<?x?xf64>, %b: tensor<?x?xf64>) -> tensor<?x?xf64> {
  %t1 = mg.add %a, %b : tensor<?x?xf64>, tensor<?x?xf64> -> tensor<?x?xf64>
  %t2 = mg.transpose %t1 : tensor<?x?xf64> to tensor<?x?xf64>
  func.return %t2 : tensor<?x?xf64>
}
func.func @main() -> i32 {
  %t1 = mg.constant dense<[[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]]> : tensor<2x3xf64>
  %t2 = mg.constant dense<[[10.0, 20.0, 30.0], [40.0, 50.0, 60.0]]> : tensor<2x3xf64>
  %t3 = tensor.cast %t1 : tensor<2x3xf64> to tensor<?x?xf64>
  %t4 = tensor.cast %t2 : tensor<2x3xf64> to tensor<?x?xf64>
  %t5 = func.call @addt(%t3, %t4) : (tensor<?x?xf64>, tensor<?x?xf64>) -> tensor<?x?xf64>
  mg.print %t5 : tensor<?x?xf64>
  %t6 = mg.constant dense<[[1.0], [2.0], [3.0]]> : tensor<3x1xf64>
  %t7 = mg.constant dense<[[0.5], [0.5], [0.5]]> : tensor<3x1xf64>
  %t8 = tensor.cast %t6 : tensor<3x1xf64> to tensor<?x?xf64>
  %t9 = tensor.cast %t7 : tensor<3x1xf64> to tensor<?x?xf64>
  %t10 = func.call @addt(%t8, %t9) : (tensor<?x?xf64>, tensor<?x?xf64>) -> tensor<?x?xf64>
  mg.print %t10 : tensor<?x?xf64>
  %zero = arith.constant 0 : i32
  func.return %zero : i32
}
