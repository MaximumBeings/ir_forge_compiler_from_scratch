// An optimization pass at work: nothing here needs the program to run, so the compiler can compute it.
func.func @five() -> i32 {
  %two = arith.constant 2 : i32
  %three = arith.constant 3 : i32
  %sum = arith.addi %two, %three : i32       // 2 + 3 is known now
  %again = arith.addi %two, %three : i32     // the very same computation, written twice
  %ten = arith.addi %sum, %again : i32       // 5 + 5
  func.return %ten : i32
}
