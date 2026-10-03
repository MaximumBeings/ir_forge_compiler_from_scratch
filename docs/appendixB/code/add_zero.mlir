func.func @add_zero(%a: i32) -> i32 {
  %zero = arith.constant 0 : i32
  %c = arith.addi %a, %zero : i32
  return %c : i32
}
