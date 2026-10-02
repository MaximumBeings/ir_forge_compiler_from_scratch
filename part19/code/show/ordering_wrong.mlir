module {
  llvm.mlir.global private constant @assert_msg_0(dense<[109, 103, 46, 97, 100, 100, 58, 32, 111, 112, 101, 114, 97, 110, 100, 32, 115, 104, 97, 112, 101, 115, 32, 100, 105, 102, 102, 101, 114, 32, 97, 116, 32, 114, 117, 110, 116, 105, 109, 101, 32, 105, 110, 32, 100, 105, 109, 101, 110, 115, 105, 111, 110, 32, 49, 0]> : tensor<56xi8>) {addr_space = 0 : i32} : !llvm.array<56 x i8>
  llvm.func @abort()
  llvm.func @puts(!llvm.ptr)
  llvm.mlir.global private constant @assert_msg(dense<[109, 103, 46, 97, 100, 100, 58, 32, 111, 112, 101, 114, 97, 110, 100, 32, 115, 104, 97, 112, 101, 115, 32, 100, 105, 102, 102, 101, 114, 32, 97, 116, 32, 114, 117, 110, 116, 105, 109, 101, 32, 105, 110, 32, 100, 105, 109, 101, 110, 115, 105, 111, 110, 32, 48, 0]> : tensor<56xi8>) {addr_space = 0 : i32} : !llvm.array<56 x i8>
  llvm.func @malloc(i64) -> !llvm.ptr
  llvm.func @add_dyn(%arg0: !llvm.ptr, %arg1: !llvm.ptr, %arg2: i64, %arg3: i64, %arg4: i64, %arg5: i64, %arg6: i64, %arg7: !llvm.ptr, %arg8: !llvm.ptr, %arg9: i64, %arg10: i64, %arg11: i64, %arg12: i64, %arg13: i64) -> !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> {
    %0 = llvm.mlir.constant(1 : index) : i64
    %1 = llvm.mlir.constant(0 : index) : i64
    %2 = llvm.mlir.undef : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
    %3 = llvm.insertvalue %arg0, %2[0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %4 = llvm.insertvalue %arg1, %3[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %5 = llvm.insertvalue %arg2, %4[2] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %6 = llvm.insertvalue %arg3, %5[3, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %7 = llvm.insertvalue %arg5, %6[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %8 = llvm.insertvalue %arg4, %7[3, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %9 = llvm.mlir.undef : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
    %10 = llvm.insertvalue %arg7, %9[0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %11 = llvm.insertvalue %arg8, %10[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %12 = llvm.insertvalue %arg9, %11[2] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %13 = llvm.insertvalue %arg10, %12[3, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %14 = llvm.insertvalue %arg12, %13[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %15 = llvm.insertvalue %arg11, %14[3, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %16 = llvm.extractvalue %8[3] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %17 = llvm.alloca %0 x !llvm.array<2 x i64> : (i64) -> !llvm.ptr
    llvm.store %16, %17 : !llvm.array<2 x i64>, !llvm.ptr
    %18 = llvm.getelementptr %17[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i64>
    %19 = llvm.load %18 : !llvm.ptr -> i64
    %20 = llvm.extractvalue %15[3] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %21 = llvm.alloca %0 x !llvm.array<2 x i64> : (i64) -> !llvm.ptr
    llvm.store %20, %21 : !llvm.array<2 x i64>, !llvm.ptr
    %22 = llvm.getelementptr %21[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i64>
    %23 = llvm.load %22 : !llvm.ptr -> i64
    %24 = llvm.icmp "eq" %19, %23 : i64
    llvm.cond_br %24, ^bb1, ^bb9
  ^bb1:  // pred: ^bb0
    %25 = llvm.extractvalue %8[3] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %26 = llvm.alloca %0 x !llvm.array<2 x i64> : (i64) -> !llvm.ptr
    llvm.store %25, %26 : !llvm.array<2 x i64>, !llvm.ptr
    %27 = llvm.getelementptr %26[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i64>
    %28 = llvm.load %27 : !llvm.ptr -> i64
    %29 = llvm.extractvalue %15[3] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %30 = llvm.alloca %0 x !llvm.array<2 x i64> : (i64) -> !llvm.ptr
    llvm.store %29, %30 : !llvm.array<2 x i64>, !llvm.ptr
    %31 = llvm.getelementptr %30[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i64>
    %32 = llvm.load %31 : !llvm.ptr -> i64
    %33 = llvm.icmp "eq" %28, %32 : i64
    llvm.cond_br %33, ^bb2, ^bb10
  ^bb2:  // pred: ^bb1
    %34 = llvm.extractvalue %8[3] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %35 = llvm.alloca %0 x !llvm.array<2 x i64> : (i64) -> !llvm.ptr
    llvm.store %34, %35 : !llvm.array<2 x i64>, !llvm.ptr
    %36 = llvm.getelementptr %35[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i64>
    %37 = llvm.load %36 : !llvm.ptr -> i64
    %38 = llvm.extractvalue %8[3] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %39 = llvm.alloca %0 x !llvm.array<2 x i64> : (i64) -> !llvm.ptr
    llvm.store %38, %39 : !llvm.array<2 x i64>, !llvm.ptr
    %40 = llvm.getelementptr %39[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i64>
    %41 = llvm.load %40 : !llvm.ptr -> i64
    %42 = llvm.mul %41, %37  : i64
    %43 = llvm.mlir.zero : !llvm.ptr
    %44 = llvm.getelementptr %43[%42] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %45 = llvm.ptrtoint %44 : !llvm.ptr to i64
    %46 = llvm.call @malloc(%45) : (i64) -> !llvm.ptr
    %47 = llvm.mlir.undef : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
    %48 = llvm.insertvalue %46, %47[0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %49 = llvm.insertvalue %46, %48[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %50 = llvm.insertvalue %1, %49[2] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %51 = llvm.insertvalue %37, %50[3, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %52 = llvm.insertvalue %41, %51[3, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %53 = llvm.insertvalue %41, %52[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %54 = llvm.insertvalue %0, %53[4, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    llvm.br ^bb3(%1 : i64)
  ^bb3(%55: i64):  // 2 preds: ^bb2, ^bb7
    %56 = llvm.icmp "slt" %55, %37 : i64
    llvm.cond_br %56, ^bb4, ^bb8
  ^bb4:  // pred: ^bb3
    llvm.br ^bb5(%1 : i64)
  ^bb5(%57: i64):  // 2 preds: ^bb4, ^bb6
    %58 = llvm.icmp "slt" %57, %41 : i64
    llvm.cond_br %58, ^bb6, ^bb7
  ^bb6:  // pred: ^bb5
    %59 = llvm.mul %55, %arg5  : i64
    %60 = llvm.add %59, %57  : i64
    %61 = llvm.getelementptr %arg1[%60] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %62 = llvm.load %61 : !llvm.ptr -> f64
    %63 = llvm.mul %55, %arg12  : i64
    %64 = llvm.add %63, %57  : i64
    %65 = llvm.getelementptr %arg8[%64] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %66 = llvm.load %65 : !llvm.ptr -> f64
    %67 = llvm.fadd %62, %66  : f64
    %68 = llvm.mul %55, %41  : i64
    %69 = llvm.add %68, %57  : i64
    %70 = llvm.getelementptr %46[%69] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %67, %70 : f64, !llvm.ptr
    %71 = llvm.add %57, %0  : i64
    llvm.br ^bb5(%71 : i64)
  ^bb7:  // pred: ^bb5
    %72 = llvm.add %55, %0  : i64
    llvm.br ^bb3(%72 : i64)
  ^bb8:  // pred: ^bb3
    llvm.return %54 : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
  ^bb9:  // pred: ^bb0
    %73 = llvm.mlir.addressof @assert_msg : !llvm.ptr
    llvm.call @puts(%73) : (!llvm.ptr) -> ()
    llvm.call @abort() : () -> ()
    llvm.unreachable
  ^bb10:  // pred: ^bb1
    %74 = llvm.mlir.addressof @assert_msg_0 : !llvm.ptr
    llvm.call @puts(%74) : (!llvm.ptr) -> ()
    llvm.call @abort() : () -> ()
    llvm.unreachable
  }
  llvm.func @t_dyn(%arg0: !llvm.ptr, %arg1: !llvm.ptr, %arg2: i64, %arg3: i64, %arg4: i64, %arg5: i64, %arg6: i64) -> !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> {
    %0 = llvm.mlir.constant(0 : index) : i64
    %1 = llvm.mlir.constant(1 : index) : i64
    %2 = llvm.mlir.undef : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
    %3 = llvm.insertvalue %arg0, %2[0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %4 = llvm.insertvalue %arg1, %3[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %5 = llvm.insertvalue %arg2, %4[2] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %6 = llvm.insertvalue %arg3, %5[3, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %7 = llvm.insertvalue %arg5, %6[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %8 = llvm.insertvalue %arg4, %7[3, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %9 = llvm.extractvalue %8[3] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %10 = llvm.alloca %1 x !llvm.array<2 x i64> : (i64) -> !llvm.ptr
    llvm.store %9, %10 : !llvm.array<2 x i64>, !llvm.ptr
    %11 = llvm.getelementptr %10[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i64>
    %12 = llvm.load %11 : !llvm.ptr -> i64
    %13 = llvm.extractvalue %8[3] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %14 = llvm.alloca %1 x !llvm.array<2 x i64> : (i64) -> !llvm.ptr
    llvm.store %13, %14 : !llvm.array<2 x i64>, !llvm.ptr
    %15 = llvm.getelementptr %14[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i64>
    %16 = llvm.load %15 : !llvm.ptr -> i64
    %17 = llvm.mul %16, %12  : i64
    %18 = llvm.mlir.zero : !llvm.ptr
    %19 = llvm.getelementptr %18[%17] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %20 = llvm.ptrtoint %19 : !llvm.ptr to i64
    %21 = llvm.call @malloc(%20) : (i64) -> !llvm.ptr
    %22 = llvm.mlir.undef : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
    %23 = llvm.insertvalue %21, %22[0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %24 = llvm.insertvalue %21, %23[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %25 = llvm.insertvalue %0, %24[2] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %26 = llvm.insertvalue %12, %25[3, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %27 = llvm.insertvalue %16, %26[3, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %28 = llvm.insertvalue %16, %27[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %29 = llvm.insertvalue %1, %28[4, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    llvm.br ^bb1(%0 : i64)
  ^bb1(%30: i64):  // 2 preds: ^bb0, ^bb5
    %31 = llvm.icmp "slt" %30, %12 : i64
    llvm.cond_br %31, ^bb2, ^bb6
  ^bb2:  // pred: ^bb1
    llvm.br ^bb3(%0 : i64)
  ^bb3(%32: i64):  // 2 preds: ^bb2, ^bb4
    %33 = llvm.icmp "slt" %32, %16 : i64
    llvm.cond_br %33, ^bb4, ^bb5
  ^bb4:  // pred: ^bb3
    %34 = llvm.mul %32, %arg5  : i64
    %35 = llvm.add %34, %30  : i64
    %36 = llvm.getelementptr %arg1[%35] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %37 = llvm.load %36 : !llvm.ptr -> f64
    %38 = llvm.mul %30, %16  : i64
    %39 = llvm.add %38, %32  : i64
    %40 = llvm.getelementptr %21[%39] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %37, %40 : f64, !llvm.ptr
    %41 = llvm.add %32, %1  : i64
    llvm.br ^bb3(%41 : i64)
  ^bb5:  // pred: ^bb3
    %42 = llvm.add %30, %1  : i64
    llvm.br ^bb1(%42 : i64)
  ^bb6:  // pred: ^bb1
    llvm.return %29 : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
  }
}

