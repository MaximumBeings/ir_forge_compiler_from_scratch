module {
  llvm.func @malloc(i64) -> !llvm.ptr
  llvm.func @mixed(%arg0: !llvm.ptr, %arg1: !llvm.ptr, %arg2: i64, %arg3: i64, %arg4: i64, %arg5: i64, %arg6: i64, %arg7: !llvm.ptr, %arg8: !llvm.ptr, %arg9: i64, %arg10: i64, %arg11: i64, %arg12: i64, %arg13: i64) -> !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> {
    %0 = llvm.mlir.undef : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
    %1 = llvm.insertvalue %arg0, %0[0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %2 = llvm.insertvalue %arg1, %1[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %3 = llvm.insertvalue %arg2, %2[2] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %4 = llvm.insertvalue %arg3, %3[3, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %5 = llvm.insertvalue %arg5, %4[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %6 = llvm.insertvalue %arg4, %5[3, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %7 = llvm.insertvalue %arg6, %6[4, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %8 = llvm.mlir.undef : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
    %9 = llvm.insertvalue %arg7, %8[0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %10 = llvm.insertvalue %arg8, %9[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %11 = llvm.insertvalue %arg9, %10[2] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %12 = llvm.insertvalue %arg10, %11[3, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %13 = llvm.insertvalue %arg12, %12[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %14 = llvm.insertvalue %arg11, %13[3, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %15 = llvm.insertvalue %arg13, %14[4, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %16 = llvm.mlir.constant(0 : index) : i64
    %17 = llvm.mlir.constant(1 : index) : i64
    %18 = llvm.extractvalue %7[3] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %19 = llvm.alloca %17 x !llvm.array<2 x i64> : (i64) -> !llvm.ptr
    llvm.store %18, %19 : !llvm.array<2 x i64>, !llvm.ptr
    %20 = llvm.getelementptr %19[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i64>
    %21 = llvm.load %20 : !llvm.ptr -> i64
    %22 = llvm.mlir.constant(2 : index) : i64
    %23 = llvm.mlir.constant(1 : index) : i64
    %24 = llvm.mul %21, %22  : i64
    %25 = llvm.mlir.zero : !llvm.ptr
    %26 = llvm.getelementptr %25[%24] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %27 = llvm.ptrtoint %26 : !llvm.ptr to i64
    %28 = llvm.call @malloc(%27) : (i64) -> !llvm.ptr
    %29 = llvm.mlir.undef : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
    %30 = llvm.insertvalue %28, %29[0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %31 = llvm.insertvalue %28, %30[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %32 = llvm.mlir.constant(0 : index) : i64
    %33 = llvm.insertvalue %32, %31[2] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %34 = llvm.insertvalue %21, %33[3, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %35 = llvm.insertvalue %22, %34[3, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %36 = llvm.insertvalue %22, %35[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %37 = llvm.insertvalue %23, %36[4, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %38 = llvm.mlir.constant(0 : index) : i64
    %39 = llvm.mlir.constant(2 : index) : i64
    %40 = llvm.mlir.constant(0 : index) : i64
    %41 = llvm.mlir.constant(1 : index) : i64
    llvm.br ^bb1(%40 : i64)
  ^bb1(%42: i64):  // 2 preds: ^bb0, ^bb5
    %43 = llvm.icmp "slt" %42, %21 : i64
    llvm.cond_br %43, ^bb2, ^bb6
  ^bb2:  // pred: ^bb1
    %44 = llvm.mlir.constant(0 : index) : i64
    %45 = llvm.mlir.constant(2 : index) : i64
    %46 = llvm.mlir.constant(1 : index) : i64
    llvm.br ^bb3(%44 : i64)
  ^bb3(%47: i64):  // 2 preds: ^bb2, ^bb4
    %48 = llvm.icmp "slt" %47, %45 : i64
    llvm.cond_br %48, ^bb4, ^bb5
  ^bb4:  // pred: ^bb3
    %49 = llvm.extractvalue %7[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %50 = llvm.mlir.constant(2 : index) : i64
    %51 = llvm.mul %42, %50  : i64
    %52 = llvm.add %51, %47  : i64
    %53 = llvm.getelementptr %49[%52] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %54 = llvm.load %53 : !llvm.ptr -> f64
    %55 = llvm.extractvalue %15[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %56 = llvm.mlir.constant(2 : index) : i64
    %57 = llvm.mul %42, %56  : i64
    %58 = llvm.add %57, %47  : i64
    %59 = llvm.getelementptr %55[%58] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %60 = llvm.load %59 : !llvm.ptr -> f64
    %61 = llvm.fadd %54, %60  : f64
    %62 = llvm.mlir.constant(2 : index) : i64
    %63 = llvm.mul %42, %62  : i64
    %64 = llvm.add %63, %47  : i64
    %65 = llvm.getelementptr %28[%64] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %61, %65 : f64, !llvm.ptr
    %66 = llvm.add %47, %46  : i64
    llvm.br ^bb3(%66 : i64)
  ^bb5:  // pred: ^bb3
    %67 = llvm.add %42, %41  : i64
    llvm.br ^bb1(%67 : i64)
  ^bb6:  // pred: ^bb1
    llvm.return %37 : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
  }
}

