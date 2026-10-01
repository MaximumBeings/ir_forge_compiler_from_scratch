func.func @sum_array(%arr: memref<5xi32>) -> i32 {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c5 = arith.constant 5 : index
  %zero = arith.constant 0 : i32
  %result = scf.for %i = %c0 to %c5 step %c1 iter_args(%sum = %zero) -> (i32) {
    %val = memref.load %arr[%i] : memref<5xi32>
    %new_sum = arith.addi %sum, %val : i32
    scf.yield %new_sum : i32
  }
  return %result : i32
}
