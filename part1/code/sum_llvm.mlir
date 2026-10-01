module {
  llvm.func @sum_array(%arg0: !llvm.ptr, %arg1: !llvm.ptr, %arg2: i64, %arg3: i64, %arg4: i64) -> i32 {
    %0 = llvm.mlir.undef : !llvm.struct<(ptr, ptr, i64, array<1 x i64>, array<1 x i64>)>
    %1 = llvm.insertvalue %arg0, %0[0] : !llvm.struct<(ptr, ptr, i64, array<1 x i64>, array<1 x i64>)> 
    %2 = llvm.insertvalue %arg1, %1[1] : !llvm.struct<(ptr, ptr, i64, array<1 x i64>, array<1 x i64>)> 
    %3 = llvm.insertvalue %arg2, %2[2] : !llvm.struct<(ptr, ptr, i64, array<1 x i64>, array<1 x i64>)> 
    %4 = llvm.insertvalue %arg3, %3[3, 0] : !llvm.struct<(ptr, ptr, i64, array<1 x i64>, array<1 x i64>)> 
    %5 = llvm.insertvalue %arg4, %4[4, 0] : !llvm.struct<(ptr, ptr, i64, array<1 x i64>, array<1 x i64>)> 
    %6 = llvm.mlir.constant(0 : index) : i64
    %7 = llvm.mlir.constant(1 : index) : i64
    %8 = llvm.mlir.constant(5 : index) : i64
    %9 = llvm.mlir.constant(0 : i32) : i32
    llvm.br ^bb1(%6, %9 : i64, i32)
  ^bb1(%10: i64, %11: i32):  // 2 preds: ^bb0, ^bb2
    %12 = llvm.icmp "slt" %10, %8 : i64
    llvm.cond_br %12, ^bb2, ^bb3
  ^bb2:  // pred: ^bb1
    %13 = llvm.extractvalue %5[1] : !llvm.struct<(ptr, ptr, i64, array<1 x i64>, array<1 x i64>)> 
    %14 = llvm.getelementptr %13[%10] : (!llvm.ptr, i64) -> !llvm.ptr, i32
    %15 = llvm.load %14 : !llvm.ptr -> i32
    %16 = llvm.add %11, %15  : i32
    %17 = llvm.add %10, %7  : i64
    llvm.br ^bb1(%17, %16 : i64, i32)
  ^bb3:  // pred: ^bb1
    llvm.return %11 : i32
  }
}

