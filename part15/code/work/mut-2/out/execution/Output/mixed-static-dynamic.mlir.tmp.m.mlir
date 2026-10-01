module {
  llvm.func @abort()
  llvm.func @puts(!llvm.ptr)
  llvm.mlir.global private constant @assert_msg(dense<[109, 103, 46, 97, 100, 100, 58, 32, 111, 112, 101, 114, 97, 110, 100, 32, 115, 104, 97, 112, 101, 115, 32, 100, 105, 102, 102, 101, 114, 32, 97, 116, 32, 114, 117, 110, 116, 105, 109, 101, 32, 105, 110, 32, 100, 105, 109, 101, 110, 115, 105, 111, 110, 32, 48, 0]> : tensor<56xi8>) {addr_space = 0 : i32} : !llvm.array<56 x i8>
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
    %22 = llvm.mlir.constant(0 : index) : i64
    %23 = llvm.mlir.constant(3 : index) : i64
    %24 = llvm.icmp "eq" %21, %23 : i64
    llvm.cond_br %24, ^bb1, ^bb8
  ^bb1:  // pred: ^bb0
    %25 = llvm.mlir.constant(0 : index) : i64
    %26 = llvm.mlir.constant(1 : index) : i64
    %27 = llvm.extractvalue %7[3] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %28 = llvm.alloca %26 x !llvm.array<2 x i64> : (i64) -> !llvm.ptr
    llvm.store %27, %28 : !llvm.array<2 x i64>, !llvm.ptr
    %29 = llvm.getelementptr %28[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i64>
    %30 = llvm.load %29 : !llvm.ptr -> i64
    %31 = llvm.mlir.constant(2 : index) : i64
    %32 = llvm.mlir.constant(1 : index) : i64
    %33 = llvm.mul %30, %31  : i64
    %34 = llvm.mlir.zero : !llvm.ptr
    %35 = llvm.getelementptr %34[%33] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %36 = llvm.ptrtoint %35 : !llvm.ptr to i64
    %37 = llvm.call @malloc(%36) : (i64) -> !llvm.ptr
    %38 = llvm.mlir.undef : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
    %39 = llvm.insertvalue %37, %38[0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %40 = llvm.insertvalue %37, %39[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %41 = llvm.mlir.constant(0 : index) : i64
    %42 = llvm.insertvalue %41, %40[2] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %43 = llvm.insertvalue %30, %42[3, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %44 = llvm.insertvalue %31, %43[3, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %45 = llvm.insertvalue %31, %44[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %46 = llvm.insertvalue %32, %45[4, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %47 = llvm.mlir.constant(0 : index) : i64
    %48 = llvm.mlir.constant(2 : index) : i64
    %49 = llvm.mlir.constant(0 : index) : i64
    %50 = llvm.mlir.constant(1 : index) : i64
    llvm.br ^bb2(%49 : i64)
  ^bb2(%51: i64):  // 2 preds: ^bb1, ^bb6
    %52 = llvm.icmp "slt" %51, %30 : i64
    llvm.cond_br %52, ^bb3, ^bb7
  ^bb3:  // pred: ^bb2
    %53 = llvm.mlir.constant(0 : index) : i64
    %54 = llvm.mlir.constant(2 : index) : i64
    %55 = llvm.mlir.constant(1 : index) : i64
    llvm.br ^bb4(%53 : i64)
  ^bb4(%56: i64):  // 2 preds: ^bb3, ^bb5
    %57 = llvm.icmp "slt" %56, %54 : i64
    llvm.cond_br %57, ^bb5, ^bb6
  ^bb5:  // pred: ^bb4
    %58 = llvm.extractvalue %7[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %59 = llvm.mlir.constant(2 : index) : i64
    %60 = llvm.mul %51, %59  : i64
    %61 = llvm.add %60, %56  : i64
    %62 = llvm.getelementptr %58[%61] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %63 = llvm.load %62 : !llvm.ptr -> f64
    %64 = llvm.extractvalue %15[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %65 = llvm.mlir.constant(2 : index) : i64
    %66 = llvm.mul %51, %65  : i64
    %67 = llvm.add %66, %56  : i64
    %68 = llvm.getelementptr %64[%67] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %69 = llvm.load %68 : !llvm.ptr -> f64
    %70 = llvm.fadd %63, %69  : f64
    %71 = llvm.mlir.constant(2 : index) : i64
    %72 = llvm.mul %51, %71  : i64
    %73 = llvm.add %72, %56  : i64
    %74 = llvm.getelementptr %37[%73] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %70, %74 : f64, !llvm.ptr
    %75 = llvm.add %56, %55  : i64
    llvm.br ^bb4(%75 : i64)
  ^bb6:  // pred: ^bb4
    %76 = llvm.add %51, %50  : i64
    llvm.br ^bb2(%76 : i64)
  ^bb7:  // pred: ^bb2
    llvm.return %46 : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
  ^bb8:  // pred: ^bb0
    %77 = llvm.mlir.addressof @assert_msg : !llvm.ptr
    llvm.call @puts(%77) : (!llvm.ptr) -> ()
    llvm.call @abort() : () -> ()
    llvm.unreachable
  }
}

