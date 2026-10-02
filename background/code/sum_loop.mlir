// A loop in MLIR, written with the 'scf' (structured control flow) dialect: sum_to(n) = 1 + 2 + ... + n.
// The loop carries 'total' from one iteration to the next ("iter_args"), and 'scf.yield' passes it on.
func.func @sum_to(%n: index) -> index {
  %zero = arith.constant 0 : index
  %one = arith.constant 1 : index
  %end = arith.addi %n, %one : index
  %total = scf.for %i = %one to %end step %one iter_args(%acc = %zero) -> (index) {
    %next = arith.addi %acc, %i : index
    scf.yield %next : index
  }
  func.return %total : index
}
