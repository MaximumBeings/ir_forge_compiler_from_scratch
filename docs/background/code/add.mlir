// MLIR: the same function as sum.c, written with two MLIR dialects.
// 'func' provides functions; 'arith' provides arithmetic. Each operation is named <dialect>.<operation>.
func.func @add(%a: i32, %b: i32) -> i32 {
  %r = arith.addi %a, %b : i32
  func.return %r : i32
}
