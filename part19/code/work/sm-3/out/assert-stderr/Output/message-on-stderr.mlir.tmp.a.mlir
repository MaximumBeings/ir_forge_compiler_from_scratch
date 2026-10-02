module {
  llvm.func @malloc(i64) -> !llvm.ptr
  llvm.mlir.global private constant @mg_assert_stderr_msg_1("mg.add: operand shapes differ at runtime in dimension 0\0A") {addr_space = 0 : i32}
  llvm.func @abort()
  llvm.func @write(i32, !llvm.ptr, i64) -> i64
  llvm.mlir.global private constant @mg_assert_stderr_msg_0("mg.add: operand shapes differ at runtime in dimension 1\0A") {addr_space = 0 : i32}
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
    %16 = llvm.mlir.constant(56 : i64) : i64
    %17 = llvm.mlir.constant(2 : i32) : i32
    %18 = llvm.mlir.constant(1 : index) : i64
    %19 = llvm.mlir.constant(0 : index) : i64
    %20 = llvm.mlir.constant(1 : index) : i64
    %21 = llvm.extractvalue %7[3] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %22 = llvm.alloca %20 x !llvm.array<2 x i64> : (i64) -> !llvm.ptr
    llvm.store %21, %22 : !llvm.array<2 x i64>, !llvm.ptr
    %23 = llvm.getelementptr %22[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i64>
    %24 = llvm.load %23 : !llvm.ptr -> i64
    %25 = llvm.mlir.constant(1 : index) : i64
    %26 = llvm.extractvalue %15[3] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %27 = llvm.alloca %25 x !llvm.array<2 x i64> : (i64) -> !llvm.ptr
    llvm.store %26, %27 : !llvm.array<2 x i64>, !llvm.ptr
    %28 = llvm.getelementptr %27[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i64>
    %29 = llvm.load %28 : !llvm.ptr -> i64
    %30 = llvm.icmp "eq" %24, %29 : i64
    llvm.cond_br %30, ^bb2, ^bb1
  ^bb1:  // pred: ^bb0
    %31 = llvm.mlir.addressof @mg_assert_stderr_msg_1 : !llvm.ptr
    %32 = llvm.call @write(%17, %31, %16) : (i32, !llvm.ptr, i64) -> i64
    llvm.call @abort() : () -> ()
    llvm.unreachable
  ^bb2:  // pred: ^bb0
    %33 = llvm.mlir.constant(1 : index) : i64
    %34 = llvm.extractvalue %7[3] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %35 = llvm.alloca %33 x !llvm.array<2 x i64> : (i64) -> !llvm.ptr
    llvm.store %34, %35 : !llvm.array<2 x i64>, !llvm.ptr
    %36 = llvm.getelementptr %35[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i64>
    %37 = llvm.load %36 : !llvm.ptr -> i64
    %38 = llvm.mlir.constant(1 : index) : i64
    %39 = llvm.extractvalue %15[3] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %40 = llvm.alloca %38 x !llvm.array<2 x i64> : (i64) -> !llvm.ptr
    llvm.store %39, %40 : !llvm.array<2 x i64>, !llvm.ptr
    %41 = llvm.getelementptr %40[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i64>
    %42 = llvm.load %41 : !llvm.ptr -> i64
    %43 = llvm.icmp "eq" %37, %42 : i64
    llvm.cond_br %43, ^bb4, ^bb3
  ^bb3:  // pred: ^bb2
    %44 = llvm.mlir.addressof @mg_assert_stderr_msg_0 : !llvm.ptr
    %45 = llvm.call @write(%17, %44, %16) : (i32, !llvm.ptr, i64) -> i64
    llvm.call @abort() : () -> ()
    llvm.unreachable
  ^bb4:  // pred: ^bb2
    %46 = llvm.mlir.constant(1 : index) : i64
    %47 = llvm.extractvalue %7[3] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %48 = llvm.alloca %46 x !llvm.array<2 x i64> : (i64) -> !llvm.ptr
    llvm.store %47, %48 : !llvm.array<2 x i64>, !llvm.ptr
    %49 = llvm.getelementptr %48[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i64>
    %50 = llvm.load %49 : !llvm.ptr -> i64
    %51 = llvm.mlir.constant(1 : index) : i64
    %52 = llvm.extractvalue %7[3] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %53 = llvm.alloca %51 x !llvm.array<2 x i64> : (i64) -> !llvm.ptr
    llvm.store %52, %53 : !llvm.array<2 x i64>, !llvm.ptr
    %54 = llvm.getelementptr %53[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i64>
    %55 = llvm.load %54 : !llvm.ptr -> i64
    %56 = llvm.mlir.constant(1 : index) : i64
    %57 = llvm.mul %55, %50  : i64
    %58 = llvm.mlir.zero : !llvm.ptr
    %59 = llvm.getelementptr %58[%57] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %60 = llvm.ptrtoint %59 : !llvm.ptr to i64
    %61 = llvm.call @malloc(%60) : (i64) -> !llvm.ptr
    %62 = llvm.mlir.undef : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
    %63 = llvm.insertvalue %61, %62[0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %64 = llvm.insertvalue %61, %63[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %65 = llvm.mlir.constant(0 : index) : i64
    %66 = llvm.insertvalue %65, %64[2] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %67 = llvm.insertvalue %50, %66[3, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %68 = llvm.insertvalue %55, %67[3, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %69 = llvm.insertvalue %55, %68[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %70 = llvm.insertvalue %56, %69[4, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    llvm.br ^bb5(%19 : i64)
  ^bb5(%71: i64):  // 2 preds: ^bb4, ^bb9
    %72 = llvm.icmp "slt" %71, %50 : i64
    llvm.cond_br %72, ^bb6, ^bb10
  ^bb6:  // pred: ^bb5
    llvm.br ^bb7(%19 : i64)
  ^bb7(%73: i64):  // 2 preds: ^bb6, ^bb8
    %74 = llvm.icmp "slt" %73, %55 : i64
    llvm.cond_br %74, ^bb8, ^bb9
  ^bb8:  // pred: ^bb7
    %75 = llvm.extractvalue %7[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %76 = llvm.extractvalue %7[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %77 = llvm.mul %71, %76  : i64
    %78 = llvm.add %77, %73  : i64
    %79 = llvm.getelementptr %75[%78] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %80 = llvm.load %79 : !llvm.ptr -> f64
    %81 = llvm.extractvalue %15[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %82 = llvm.extractvalue %15[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %83 = llvm.mul %71, %82  : i64
    %84 = llvm.add %83, %73  : i64
    %85 = llvm.getelementptr %81[%84] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %86 = llvm.load %85 : !llvm.ptr -> f64
    %87 = llvm.fadd %80, %86  : f64
    %88 = llvm.mul %71, %55  : i64
    %89 = llvm.add %88, %73  : i64
    %90 = llvm.getelementptr %61[%89] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %87, %90 : f64, !llvm.ptr
    %91 = llvm.add %73, %18  : i64
    llvm.br ^bb7(%91 : i64)
  ^bb9:  // pred: ^bb7
    %92 = llvm.add %71, %18  : i64
    llvm.br ^bb5(%92 : i64)
  ^bb10:  // pred: ^bb5
    llvm.return %70 : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
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
    %8 = llvm.mlir.constant(0 : index) : i64
    %9 = llvm.mlir.constant(1 : index) : i64
    %10 = llvm.mlir.constant(1 : index) : i64
    %11 = llvm.extractvalue %7[3] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %12 = llvm.alloca %10 x !llvm.array<2 x i64> : (i64) -> !llvm.ptr
    llvm.store %11, %12 : !llvm.array<2 x i64>, !llvm.ptr
    %13 = llvm.getelementptr %12[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i64>
    %14 = llvm.load %13 : !llvm.ptr -> i64
    %15 = llvm.mlir.constant(1 : index) : i64
    %16 = llvm.extractvalue %7[3] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %17 = llvm.alloca %15 x !llvm.array<2 x i64> : (i64) -> !llvm.ptr
    llvm.store %16, %17 : !llvm.array<2 x i64>, !llvm.ptr
    %18 = llvm.getelementptr %17[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i64>
    %19 = llvm.load %18 : !llvm.ptr -> i64
    %20 = llvm.mlir.constant(1 : index) : i64
    %21 = llvm.mul %19, %14  : i64
    %22 = llvm.mlir.zero : !llvm.ptr
    %23 = llvm.getelementptr %22[%21] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %24 = llvm.ptrtoint %23 : !llvm.ptr to i64
    %25 = llvm.call @malloc(%24) : (i64) -> !llvm.ptr
    %26 = llvm.mlir.undef : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
    %27 = llvm.insertvalue %25, %26[0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %28 = llvm.insertvalue %25, %27[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %29 = llvm.mlir.constant(0 : index) : i64
    %30 = llvm.insertvalue %29, %28[2] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %31 = llvm.insertvalue %14, %30[3, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %32 = llvm.insertvalue %19, %31[3, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %33 = llvm.insertvalue %19, %32[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %34 = llvm.insertvalue %20, %33[4, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    llvm.br ^bb1(%8 : i64)
  ^bb1(%35: i64):  // 2 preds: ^bb0, ^bb5
    %36 = llvm.icmp "slt" %35, %14 : i64
    llvm.cond_br %36, ^bb2, ^bb6
  ^bb2:  // pred: ^bb1
    llvm.br ^bb3(%8 : i64)
  ^bb3(%37: i64):  // 2 preds: ^bb2, ^bb4
    %38 = llvm.icmp "slt" %37, %19 : i64
    llvm.cond_br %38, ^bb4, ^bb5
  ^bb4:  // pred: ^bb3
    %39 = llvm.extractvalue %7[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %40 = llvm.extractvalue %7[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %41 = llvm.mul %37, %40  : i64
    %42 = llvm.add %41, %35  : i64
    %43 = llvm.getelementptr %39[%42] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %44 = llvm.load %43 : !llvm.ptr -> f64
    %45 = llvm.mul %35, %19  : i64
    %46 = llvm.add %45, %37  : i64
    %47 = llvm.getelementptr %25[%46] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %44, %47 : f64, !llvm.ptr
    %48 = llvm.add %37, %9  : i64
    llvm.br ^bb3(%48 : i64)
  ^bb5:  // pred: ^bb3
    %49 = llvm.add %35, %9  : i64
    llvm.br ^bb1(%49 : i64)
  ^bb6:  // pred: ^bb1
    llvm.return %34 : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
  }
}

