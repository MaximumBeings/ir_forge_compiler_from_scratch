module {
  llvm.func @write(i32, !llvm.ptr, i64) -> i64
  llvm.mlir.global private constant @mg_assert_stderr_msg_0("bad \22quote\22 100% done, na\C3\AFve caf\C3\A9\0A") {addr_space = 0 : i32}
  llvm.func @abort()
  llvm.func @boom() {
    %0 = llvm.mlir.constant(36 : i64) : i64
    %1 = llvm.mlir.constant(2 : i32) : i32
    %2 = llvm.mlir.constant(false) : i1
    llvm.cond_br %2, ^bb2, ^bb1
  ^bb1:  // pred: ^bb0
    %3 = llvm.mlir.addressof @mg_assert_stderr_msg_0 : !llvm.ptr
    %4 = llvm.call @write(%1, %3, %0) : (i32, !llvm.ptr, i64) -> i64
    llvm.call @abort() : () -> ()
    llvm.unreachable
  ^bb2:  // pred: ^bb0
    llvm.return
  }
}

