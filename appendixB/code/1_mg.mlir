func.func @scale_add(%x: tensor<1x3xf64>, %y: tensor<1x3xf64>) -> tensor<1x3xf64> {
  %t1 = mg.scalar %x {op = "mul", value = 2.0 : f64, reversed = false} : tensor<1x3xf64> -> tensor<1x3xf64>
  %t2 = mg.add %t1, %y : tensor<1x3xf64>, tensor<1x3xf64> -> tensor<1x3xf64>
  func.return %t2 : tensor<1x3xf64>
}
func.func @main() -> i32 {
  %t1 = mg.constant dense<[[1.0, 2.0, 3.0]]> : tensor<1x3xf64>
  %t2 = mg.constant dense<[[10.0, 20.0, 30.0]]> : tensor<1x3xf64>
  %t3 = func.call @scale_add(%t1, %t2) : (tensor<1x3xf64>, tensor<1x3xf64>) -> tensor<1x3xf64>
  mg.print %t3 : tensor<1x3xf64>
  %zero = arith.constant 0 : i32
  func.return %zero : i32
}
