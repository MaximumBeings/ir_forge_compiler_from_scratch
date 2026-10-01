module {
  llvm.func @malloc(i64) -> !llvm.ptr
  llvm.func @add_tensors(%arg0: !llvm.ptr, %arg1: !llvm.ptr, %arg2: i64, %arg3: i64, %arg4: i64, %arg5: i64, %arg6: i64, %arg7: !llvm.ptr, %arg8: !llvm.ptr, %arg9: i64, %arg10: i64, %arg11: i64, %arg12: i64, %arg13: i64) -> !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> {
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
    %16 = llvm.mlir.constant(2 : index) : i64
    %17 = llvm.mlir.constant(2 : index) : i64
    %18 = llvm.mlir.constant(1 : index) : i64
    %19 = llvm.mlir.constant(4 : index) : i64
    %20 = llvm.mlir.zero : !llvm.ptr
    %21 = llvm.getelementptr %20[4] : (!llvm.ptr) -> !llvm.ptr, f64
    %22 = llvm.ptrtoint %21 : !llvm.ptr to i64
    %23 = llvm.call @malloc(%22) : (i64) -> !llvm.ptr
    %24 = llvm.mlir.undef : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
    %25 = llvm.insertvalue %23, %24[0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %26 = llvm.insertvalue %23, %25[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %27 = llvm.mlir.constant(0 : index) : i64
    %28 = llvm.insertvalue %27, %26[2] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %29 = llvm.insertvalue %16, %28[3, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %30 = llvm.insertvalue %17, %29[3, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %31 = llvm.insertvalue %17, %30[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %32 = llvm.insertvalue %18, %31[4, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %33 = llvm.mlir.constant(0 : index) : i64
    %34 = llvm.mlir.constant(2 : index) : i64
    %35 = llvm.mlir.constant(1 : index) : i64
    llvm.br ^bb1(%33 : i64)
  ^bb1(%36: i64):  // 2 preds: ^bb0, ^bb5
    %37 = llvm.icmp "slt" %36, %34 : i64
    llvm.cond_br %37, ^bb2, ^bb6
  ^bb2:  // pred: ^bb1
    %38 = llvm.mlir.constant(0 : index) : i64
    %39 = llvm.mlir.constant(2 : index) : i64
    %40 = llvm.mlir.constant(1 : index) : i64
    llvm.br ^bb3(%38 : i64)
  ^bb3(%41: i64):  // 2 preds: ^bb2, ^bb4
    %42 = llvm.icmp "slt" %41, %39 : i64
    llvm.cond_br %42, ^bb4, ^bb5
  ^bb4:  // pred: ^bb3
    %43 = llvm.extractvalue %7[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %44 = llvm.extractvalue %7[2] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %45 = llvm.getelementptr %43[%44] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %46 = llvm.extractvalue %7[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %47 = llvm.mul %36, %46  : i64
    %48 = llvm.extractvalue %7[4, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %49 = llvm.mul %41, %48  : i64
    %50 = llvm.add %47, %49  : i64
    %51 = llvm.getelementptr %45[%50] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %52 = llvm.load %51 : !llvm.ptr -> f64
    %53 = llvm.extractvalue %15[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %54 = llvm.extractvalue %15[2] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %55 = llvm.getelementptr %53[%54] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %56 = llvm.extractvalue %15[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %57 = llvm.mul %36, %56  : i64
    %58 = llvm.extractvalue %15[4, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %59 = llvm.mul %41, %58  : i64
    %60 = llvm.add %57, %59  : i64
    %61 = llvm.getelementptr %55[%60] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %62 = llvm.load %61 : !llvm.ptr -> f64
    %63 = llvm.fadd %52, %62  : f64
    %64 = llvm.mlir.constant(2 : index) : i64
    %65 = llvm.mul %36, %64  : i64
    %66 = llvm.add %65, %41  : i64
    %67 = llvm.getelementptr %23[%66] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %63, %67 : f64, !llvm.ptr
    %68 = llvm.add %41, %40  : i64
    llvm.br ^bb3(%68 : i64)
  ^bb5:  // pred: ^bb3
    %69 = llvm.add %36, %35  : i64
    llvm.br ^bb1(%69 : i64)
  ^bb6:  // pred: ^bb1
    llvm.return %32 : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
  }
}

