module {
  llvm.func @abort()
  llvm.func @puts(!llvm.ptr)
  llvm.mlir.global private constant @assert_msg(dense<[109, 103, 46, 97, 100, 100, 58, 32, 111, 112, 101, 114, 97, 110, 100, 32, 115, 104, 97, 112, 101, 115, 32, 100, 105, 102, 102, 101, 114, 32, 97, 116, 32, 114, 117, 110, 116, 105, 109, 101, 32, 105, 110, 32, 100, 105, 109, 101, 110, 115, 105, 111, 110, 32, 48, 0]> : tensor<56xi8>) {addr_space = 0 : i32} : !llvm.array<56 x i8>
  llvm.func @malloc(i64) -> !llvm.ptr
  llvm.func @add_dyn(%arg0: !llvm.ptr, %arg1: !llvm.ptr, %arg2: i64, %arg3: i64, %arg4: i64, %arg5: i64, %arg6: i64, %arg7: !llvm.ptr, %arg8: !llvm.ptr, %arg9: i64, %arg10: i64, %arg11: i64, %arg12: i64, %arg13: i64) -> !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> {
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
    %22 = llvm.mlir.constant(0 : index) : i64
    %23 = llvm.mlir.constant(1 : index) : i64
    %24 = llvm.extractvalue %15[3] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %25 = llvm.alloca %23 x !llvm.array<2 x i64> : (i64) -> !llvm.ptr
    llvm.store %24, %25 : !llvm.array<2 x i64>, !llvm.ptr
    %26 = llvm.getelementptr %25[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i64>
    %27 = llvm.load %26 : !llvm.ptr -> i64
    %28 = llvm.icmp "eq" %21, %27 : i64
    llvm.cond_br %28, ^bb1, ^bb8
  ^bb1:  // pred: ^bb0
    %29 = llvm.mlir.constant(0 : index) : i64
    %30 = llvm.mlir.constant(1 : index) : i64
    %31 = llvm.extractvalue %7[3] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %32 = llvm.alloca %30 x !llvm.array<2 x i64> : (i64) -> !llvm.ptr
    llvm.store %31, %32 : !llvm.array<2 x i64>, !llvm.ptr
    %33 = llvm.getelementptr %32[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i64>
    %34 = llvm.load %33 : !llvm.ptr -> i64
    %35 = llvm.mlir.constant(1 : index) : i64
    %36 = llvm.mlir.constant(1 : index) : i64
    %37 = llvm.extractvalue %7[3] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %38 = llvm.alloca %36 x !llvm.array<2 x i64> : (i64) -> !llvm.ptr
    llvm.store %37, %38 : !llvm.array<2 x i64>, !llvm.ptr
    %39 = llvm.getelementptr %38[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i64>
    %40 = llvm.load %39 : !llvm.ptr -> i64
    %41 = llvm.mlir.constant(1 : index) : i64
    %42 = llvm.mul %40, %34  : i64
    %43 = llvm.mlir.zero : !llvm.ptr
    %44 = llvm.getelementptr %43[%42] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %45 = llvm.ptrtoint %44 : !llvm.ptr to i64
    %46 = llvm.call @malloc(%45) : (i64) -> !llvm.ptr
    %47 = llvm.mlir.undef : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
    %48 = llvm.insertvalue %46, %47[0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %49 = llvm.insertvalue %46, %48[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %50 = llvm.mlir.constant(0 : index) : i64
    %51 = llvm.insertvalue %50, %49[2] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %52 = llvm.insertvalue %34, %51[3, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %53 = llvm.insertvalue %40, %52[3, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %54 = llvm.insertvalue %40, %53[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %55 = llvm.insertvalue %41, %54[4, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %56 = llvm.mlir.constant(0 : index) : i64
    %57 = llvm.mlir.constant(0 : index) : i64
    %58 = llvm.mlir.constant(1 : index) : i64
    llvm.br ^bb2(%57 : i64)
  ^bb2(%59: i64):  // 2 preds: ^bb1, ^bb6
    %60 = llvm.icmp "slt" %59, %34 : i64
    llvm.cond_br %60, ^bb3, ^bb7
  ^bb3:  // pred: ^bb2
    %61 = llvm.mlir.constant(0 : index) : i64
    %62 = llvm.mlir.constant(1 : index) : i64
    llvm.br ^bb4(%61 : i64)
  ^bb4(%63: i64):  // 2 preds: ^bb3, ^bb5
    %64 = llvm.icmp "slt" %63, %40 : i64
    llvm.cond_br %64, ^bb5, ^bb6
  ^bb5:  // pred: ^bb4
    %65 = llvm.extractvalue %7[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %66 = llvm.extractvalue %7[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %67 = llvm.mul %59, %66  : i64
    %68 = llvm.add %67, %63  : i64
    %69 = llvm.getelementptr %65[%68] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %70 = llvm.load %69 : !llvm.ptr -> f64
    %71 = llvm.extractvalue %15[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %72 = llvm.extractvalue %15[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %73 = llvm.mul %59, %72  : i64
    %74 = llvm.add %73, %63  : i64
    %75 = llvm.getelementptr %71[%74] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %76 = llvm.load %75 : !llvm.ptr -> f64
    %77 = llvm.fadd %70, %76  : f64
    %78 = llvm.mul %59, %40  : i64
    %79 = llvm.add %78, %63  : i64
    %80 = llvm.getelementptr %46[%79] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %77, %80 : f64, !llvm.ptr
    %81 = llvm.add %63, %62  : i64
    llvm.br ^bb4(%81 : i64)
  ^bb6:  // pred: ^bb4
    %82 = llvm.add %59, %58  : i64
    llvm.br ^bb2(%82 : i64)
  ^bb7:  // pred: ^bb2
    llvm.return %55 : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
  ^bb8:  // pred: ^bb0
    %83 = llvm.mlir.addressof @assert_msg : !llvm.ptr
    llvm.call @puts(%83) : (!llvm.ptr) -> ()
    llvm.call @abort() : () -> ()
    llvm.unreachable
  }
  llvm.func @t_dyn(%arg0: !llvm.ptr, %arg1: !llvm.ptr, %arg2: i64, %arg3: i64, %arg4: i64, %arg5: i64, %arg6: i64) -> !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> {
    %0 = llvm.mlir.undef : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
    %1 = llvm.insertvalue %arg0, %0[0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %2 = llvm.insertvalue %arg1, %1[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %3 = llvm.insertvalue %arg2, %2[2] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %4 = llvm.insertvalue %arg3, %3[3, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %5 = llvm.insertvalue %arg5, %4[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %6 = llvm.insertvalue %arg4, %5[3, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %7 = llvm.insertvalue %arg6, %6[4, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %8 = llvm.mlir.constant(1 : index) : i64
    %9 = llvm.mlir.constant(1 : index) : i64
    %10 = llvm.extractvalue %7[3] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %11 = llvm.alloca %9 x !llvm.array<2 x i64> : (i64) -> !llvm.ptr
    llvm.store %10, %11 : !llvm.array<2 x i64>, !llvm.ptr
    %12 = llvm.getelementptr %11[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i64>
    %13 = llvm.load %12 : !llvm.ptr -> i64
    %14 = llvm.mlir.constant(0 : index) : i64
    %15 = llvm.mlir.constant(1 : index) : i64
    %16 = llvm.extractvalue %7[3] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %17 = llvm.alloca %15 x !llvm.array<2 x i64> : (i64) -> !llvm.ptr
    llvm.store %16, %17 : !llvm.array<2 x i64>, !llvm.ptr
    %18 = llvm.getelementptr %17[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i64>
    %19 = llvm.load %18 : !llvm.ptr -> i64
    %20 = llvm.mlir.constant(1 : index) : i64
    %21 = llvm.mul %19, %13  : i64
    %22 = llvm.mlir.zero : !llvm.ptr
    %23 = llvm.getelementptr %22[%21] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %24 = llvm.ptrtoint %23 : !llvm.ptr to i64
    %25 = llvm.call @malloc(%24) : (i64) -> !llvm.ptr
    %26 = llvm.mlir.undef : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
    %27 = llvm.insertvalue %25, %26[0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %28 = llvm.insertvalue %25, %27[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %29 = llvm.mlir.constant(0 : index) : i64
    %30 = llvm.insertvalue %29, %28[2] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %31 = llvm.insertvalue %13, %30[3, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %32 = llvm.insertvalue %19, %31[3, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %33 = llvm.insertvalue %19, %32[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %34 = llvm.insertvalue %20, %33[4, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %35 = llvm.mlir.constant(0 : index) : i64
    %36 = llvm.mlir.constant(0 : index) : i64
    %37 = llvm.mlir.constant(1 : index) : i64
    llvm.br ^bb1(%36 : i64)
  ^bb1(%38: i64):  // 2 preds: ^bb0, ^bb5
    %39 = llvm.icmp "slt" %38, %13 : i64
    llvm.cond_br %39, ^bb2, ^bb6
  ^bb2:  // pred: ^bb1
    %40 = llvm.mlir.constant(0 : index) : i64
    %41 = llvm.mlir.constant(1 : index) : i64
    llvm.br ^bb3(%40 : i64)
  ^bb3(%42: i64):  // 2 preds: ^bb2, ^bb4
    %43 = llvm.icmp "slt" %42, %19 : i64
    llvm.cond_br %43, ^bb4, ^bb5
  ^bb4:  // pred: ^bb3
    %44 = llvm.extractvalue %7[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %45 = llvm.extractvalue %7[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %46 = llvm.mul %42, %45  : i64
    %47 = llvm.add %46, %38  : i64
    %48 = llvm.getelementptr %44[%47] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %49 = llvm.load %48 : !llvm.ptr -> f64
    %50 = llvm.mul %38, %19  : i64
    %51 = llvm.add %50, %42  : i64
    %52 = llvm.getelementptr %25[%51] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %49, %52 : f64, !llvm.ptr
    %53 = llvm.add %42, %41  : i64
    llvm.br ^bb3(%53 : i64)
  ^bb5:  // pred: ^bb3
    %54 = llvm.add %38, %37  : i64
    llvm.br ^bb1(%54 : i64)
  ^bb6:  // pred: ^bb1
    llvm.return %34 : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
  }
}

