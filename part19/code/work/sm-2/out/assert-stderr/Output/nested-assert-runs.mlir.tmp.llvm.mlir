module {
  llvm.func @abort()
  llvm.func @write(i32, !llvm.ptr, i64) -> i64
  llvm.mlir.global private constant @mg_assert_stderr_msg_0("value is NaN\0A") {addr_space = 0 : i32}
  llvm.func @nanloop(%arg0: !llvm.ptr, %arg1: !llvm.ptr, %arg2: i64, %arg3: i64, %arg4: i64, %arg5: i64) {
    %0 = llvm.mlir.undef : !llvm.struct<(ptr, ptr, i64, array<1 x i64>, array<1 x i64>)>
    %1 = llvm.insertvalue %arg0, %0[0] : !llvm.struct<(ptr, ptr, i64, array<1 x i64>, array<1 x i64>)> 
    %2 = llvm.insertvalue %arg1, %1[1] : !llvm.struct<(ptr, ptr, i64, array<1 x i64>, array<1 x i64>)> 
    %3 = llvm.insertvalue %arg2, %2[2] : !llvm.struct<(ptr, ptr, i64, array<1 x i64>, array<1 x i64>)> 
    %4 = llvm.insertvalue %arg3, %3[3, 0] : !llvm.struct<(ptr, ptr, i64, array<1 x i64>, array<1 x i64>)> 
    %5 = llvm.insertvalue %arg4, %4[4, 0] : !llvm.struct<(ptr, ptr, i64, array<1 x i64>, array<1 x i64>)> 
    %6 = llvm.mlir.constant(13 : i64) : i64
    %7 = llvm.mlir.constant(2 : i32) : i32
    %8 = llvm.mlir.constant(0 : index) : i64
    %9 = llvm.mlir.constant(1 : index) : i64
    llvm.br ^bb1(%8 : i64)
  ^bb1(%10: i64):  // 2 preds: ^bb0, ^bb4
    %11 = llvm.icmp "slt" %10, %arg5 : i64
    llvm.cond_br %11, ^bb2, ^bb5
  ^bb2:  // pred: ^bb1
    %12 = llvm.extractvalue %5[1] : !llvm.struct<(ptr, ptr, i64, array<1 x i64>, array<1 x i64>)> 
    %13 = llvm.getelementptr %12[%10] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %14 = llvm.load %13 : !llvm.ptr -> f64
    %15 = llvm.fcmp "oeq" %14, %14 : f64
    llvm.cond_br %15, ^bb4, ^bb3
  ^bb3:  // pred: ^bb2
    %16 = llvm.mlir.addressof @mg_assert_stderr_msg_0 : !llvm.ptr
    %17 = llvm.call @write(%7, %16, %6) : (i32, !llvm.ptr, i64) -> i64
    llvm.br ^bb4
  ^bb4:  // 2 preds: ^bb2, ^bb3
    %18 = llvm.add %10, %9  : i64
    llvm.br ^bb1(%18 : i64)
  ^bb5:  // pred: ^bb1
    llvm.return
  }
}

