module {
  llvm.mlir.global private constant @mg_assert_stderr_msg_1("value is NaN\0A") {addr_space = 0 : i32}
  llvm.func @abort()
  llvm.func @write(i32, !llvm.ptr, i64) -> i64
  llvm.mlir.global private constant @mg_assert_stderr_msg_0("top-level check\0A") {addr_space = 0 : i32}
  func.func @f(%arg0: memref<?xf64>, %arg1: index, %arg2: i1) {
    %0 = llvm.mlir.constant(13 : i64) : i64
    %c1 = arith.constant 1 : index
    %c0 = arith.constant 0 : index
    %1 = llvm.mlir.constant(16 : i64) : i64
    %2 = llvm.mlir.constant(2 : i32) : i32
    cf.cond_br %arg2, ^bb2, ^bb1
  ^bb1:  // pred: ^bb0
    %3 = llvm.mlir.addressof @mg_assert_stderr_msg_0 : !llvm.ptr
    %4 = llvm.call @write(%2, %3, %1) : (i32, !llvm.ptr, i64) -> i64
    llvm.call @abort() : () -> ()
    llvm.unreachable
  ^bb2:  // pred: ^bb0
    cf.br ^bb3(%c0 : index)
  ^bb3(%5: index):  // 2 preds: ^bb2, ^bb6
    %6 = arith.cmpi slt, %5, %arg1 : index
    cf.cond_br %6, ^bb4, ^bb7
  ^bb4:  // pred: ^bb3
    %7 = memref.load %arg0[%5] : memref<?xf64>
    %8 = arith.cmpf oeq, %7, %7 : f64
    cf.cond_br %8, ^bb6, ^bb5
  ^bb5:  // pred: ^bb4
    %9 = llvm.mlir.addressof @mg_assert_stderr_msg_1 : !llvm.ptr
    %10 = llvm.call @write(%2, %9, %0) : (i32, !llvm.ptr, i64) -> i64
    llvm.call @abort() : () -> ()
    llvm.unreachable
  ^bb6:  // pred: ^bb4
    %11 = arith.addi %5, %c1 : index
    cf.br ^bb3(%11 : index)
  ^bb7:  // pred: ^bb3
    return
  }
}

