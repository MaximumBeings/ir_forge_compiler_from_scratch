func.func @layer(%x: tensor<2x3xf64>, %w: tensor<3x2xf64>, %bias: tensor<1x2xf64>) -> tensor<2x2xf64> {
  %t1 = mg.matmul %x, %w : tensor<2x3xf64>, tensor<3x2xf64> -> tensor<2x2xf64>
  %t2 = mg.broadcast %bias : tensor<1x2xf64> -> tensor<2x2xf64>
  %t3 = mg.add %t1, %t2 : tensor<2x2xf64>, tensor<2x2xf64> -> tensor<2x2xf64>
  %t4 = mg.relu %t3 : tensor<2x2xf64> -> tensor<2x2xf64>
  func.return %t4 : tensor<2x2xf64>
}
func.func @main() -> i32 {
  %t1 = mg.constant dense<[[1.0, 2.0, 3.0], [-1.0, -2.0, -3.0]]> : tensor<2x3xf64>
  %t2 = mg.constant dense<[[1.0, -1.0], [0.0, 1.0], [1.0, 0.0]]> : tensor<3x2xf64>
  %t3 = mg.constant dense<[[0.5, -10.0]]> : tensor<1x2xf64>
  %t4 = func.call @layer(%t1, %t2, %t3) : (tensor<2x3xf64>, tensor<3x2xf64>, tensor<1x2xf64>) -> tensor<2x2xf64>
  mg.print %t4 : tensor<2x2xf64>
  %zero = arith.constant 0 : i32
  func.return %zero : i32
}
