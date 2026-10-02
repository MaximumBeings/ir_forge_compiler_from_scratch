module {
  llvm.func @abort()
  llvm.func @write(i32, !llvm.ptr, i64) -> i64
  llvm.mlir.global private constant @mg_assert_stderr_msg_0("value is NaN\0A") {addr_space = 0 : i32}
  func.func @nanloop(%arg0: memref<?xf64>, %arg1: index) {
    %0 = llvm.mlir.constant(13 : i64) : i64
    %1 = llvm.mlir.constant(2 : i32) : i32
    %c0 = arith.constant 0 : index
    %c1 = arith.constant 1 : index
    cf.br ^bb1(%c0 : index)
  ^bb1(%2: index):  // 2 preds: ^bb0, ^bb4
    %3 = arith.cmpi slt, %2, %arg1 : index
    cf.cond_br %3, ^bb2, ^bb5
  ^bb2:  // pred: ^bb1
    %4 = memref.load %arg0[%2] : memref<?xf64>
    %5 = arith.cmpf oeq, %4, %4 : f64
    cf.cond_br %5, ^bb4, ^bb3
  ^bb3:  // pred: ^bb2
    %6 = llvm.mlir.addressof @mg_assert_stderr_msg_0 : !llvm.ptr
    %7 = llvm.call @write(%1, %6, %0) : (i32, !llvm.ptr, i64) -> i64
    llvm.call @abort() : () -> ()
    llvm.unreachable
  ^bb4:  // pred: ^bb2
    %8 = arith.addi %2, %c1 : index
    cf.br ^bb1(%8 : index)
  ^bb5:  // pred: ^bb1
    return
  }
}

