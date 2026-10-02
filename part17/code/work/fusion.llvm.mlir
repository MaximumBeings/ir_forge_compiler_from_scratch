module {
  llvm.mlir.global private constant @assert_msg_0(dense<[109, 103, 46, 97, 100, 100, 58, 32, 111, 112, 101, 114, 97, 110, 100, 32, 115, 104, 97, 112, 101, 115, 32, 100, 105, 102, 102, 101, 114, 32, 97, 116, 32, 114, 117, 110, 116, 105, 109, 101, 32, 105, 110, 32, 100, 105, 109, 101, 110, 115, 105, 111, 110, 32, 49, 0]> : tensor<56xi8>) {addr_space = 0 : i32} : !llvm.array<56 x i8>
  llvm.func @abort()
  llvm.func @puts(!llvm.ptr)
  llvm.mlir.global private constant @assert_msg(dense<[109, 103, 46, 97, 100, 100, 58, 32, 111, 112, 101, 114, 97, 110, 100, 32, 115, 104, 97, 112, 101, 115, 32, 100, 105, 102, 102, 101, 114, 32, 97, 116, 32, 114, 117, 110, 116, 105, 109, 101, 32, 105, 110, 32, 100, 105, 109, 101, 110, 115, 105, 111, 110, 32, 48, 0]> : tensor<56xi8>) {addr_space = 0 : i32} : !llvm.array<56 x i8>
  llvm.func @malloc(i64) -> !llvm.ptr
  llvm.func @chain(%arg0: !llvm.ptr, %arg1: !llvm.ptr, %arg2: i64, %arg3: i64, %arg4: i64, %arg5: i64, %arg6: i64, %arg7: !llvm.ptr, %arg8: !llvm.ptr, %arg9: i64, %arg10: i64, %arg11: i64, %arg12: i64, %arg13: i64) -> !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> {
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
    llvm.cond_br %28, ^bb1, ^bb15
  ^bb1:  // pred: ^bb0
    %29 = llvm.mlir.constant(1 : index) : i64
    %30 = llvm.mlir.constant(1 : index) : i64
    %31 = llvm.extractvalue %7[3] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %32 = llvm.alloca %30 x !llvm.array<2 x i64> : (i64) -> !llvm.ptr
    llvm.store %31, %32 : !llvm.array<2 x i64>, !llvm.ptr
    %33 = llvm.getelementptr %32[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i64>
    %34 = llvm.load %33 : !llvm.ptr -> i64
    %35 = llvm.mlir.constant(1 : index) : i64
    %36 = llvm.mlir.constant(1 : index) : i64
    %37 = llvm.extractvalue %15[3] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %38 = llvm.alloca %36 x !llvm.array<2 x i64> : (i64) -> !llvm.ptr
    llvm.store %37, %38 : !llvm.array<2 x i64>, !llvm.ptr
    %39 = llvm.getelementptr %38[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i64>
    %40 = llvm.load %39 : !llvm.ptr -> i64
    %41 = llvm.icmp "eq" %34, %40 : i64
    llvm.cond_br %41, ^bb2, ^bb16
  ^bb2:  // pred: ^bb1
    %42 = llvm.mlir.constant(0 : index) : i64
    %43 = llvm.mlir.constant(1 : index) : i64
    %44 = llvm.extractvalue %7[3] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %45 = llvm.alloca %43 x !llvm.array<2 x i64> : (i64) -> !llvm.ptr
    llvm.store %44, %45 : !llvm.array<2 x i64>, !llvm.ptr
    %46 = llvm.getelementptr %45[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i64>
    %47 = llvm.load %46 : !llvm.ptr -> i64
    %48 = llvm.mlir.constant(1 : index) : i64
    %49 = llvm.mlir.constant(1 : index) : i64
    %50 = llvm.extractvalue %7[3] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %51 = llvm.alloca %49 x !llvm.array<2 x i64> : (i64) -> !llvm.ptr
    llvm.store %50, %51 : !llvm.array<2 x i64>, !llvm.ptr
    %52 = llvm.getelementptr %51[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i64>
    %53 = llvm.load %52 : !llvm.ptr -> i64
    %54 = llvm.mlir.constant(1 : index) : i64
    %55 = llvm.mul %53, %47  : i64
    %56 = llvm.mlir.zero : !llvm.ptr
    %57 = llvm.getelementptr %56[%55] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %58 = llvm.ptrtoint %57 : !llvm.ptr to i64
    %59 = llvm.call @malloc(%58) : (i64) -> !llvm.ptr
    %60 = llvm.mlir.undef : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
    %61 = llvm.insertvalue %59, %60[0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %62 = llvm.insertvalue %59, %61[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %63 = llvm.mlir.constant(0 : index) : i64
    %64 = llvm.insertvalue %63, %62[2] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %65 = llvm.insertvalue %47, %64[3, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %66 = llvm.insertvalue %53, %65[3, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %67 = llvm.insertvalue %53, %66[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %68 = llvm.insertvalue %54, %67[4, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %69 = llvm.mlir.constant(0 : index) : i64
    %70 = llvm.mlir.constant(0 : index) : i64
    %71 = llvm.mlir.constant(1 : index) : i64
    llvm.br ^bb3(%70 : i64)
  ^bb3(%72: i64):  // 2 preds: ^bb2, ^bb7
    %73 = llvm.icmp "slt" %72, %47 : i64
    llvm.cond_br %73, ^bb4, ^bb8
  ^bb4:  // pred: ^bb3
    %74 = llvm.mlir.constant(0 : index) : i64
    %75 = llvm.mlir.constant(1 : index) : i64
    llvm.br ^bb5(%74 : i64)
  ^bb5(%76: i64):  // 2 preds: ^bb4, ^bb6
    %77 = llvm.icmp "slt" %76, %53 : i64
    llvm.cond_br %77, ^bb6, ^bb7
  ^bb6:  // pred: ^bb5
    %78 = llvm.extractvalue %7[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %79 = llvm.extractvalue %7[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %80 = llvm.mul %72, %79  : i64
    %81 = llvm.add %80, %76  : i64
    %82 = llvm.getelementptr %78[%81] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %83 = llvm.load %82 : !llvm.ptr -> f64
    %84 = llvm.extractvalue %15[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %85 = llvm.extractvalue %15[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %86 = llvm.mul %72, %85  : i64
    %87 = llvm.add %86, %76  : i64
    %88 = llvm.getelementptr %84[%87] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %89 = llvm.load %88 : !llvm.ptr -> f64
    %90 = llvm.fadd %83, %89  : f64
    %91 = llvm.mul %72, %53  : i64
    %92 = llvm.add %91, %76  : i64
    %93 = llvm.getelementptr %59[%92] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %90, %93 : f64, !llvm.ptr
    %94 = llvm.add %76, %75  : i64
    llvm.br ^bb5(%94 : i64)
  ^bb7:  // pred: ^bb5
    %95 = llvm.add %72, %71  : i64
    llvm.br ^bb3(%95 : i64)
  ^bb8:  // pred: ^bb3
    %96 = llvm.mlir.constant(1 : index) : i64
    %97 = llvm.mlir.constant(0 : index) : i64
    %98 = llvm.mlir.constant(1 : index) : i64
    %99 = llvm.mul %47, %53  : i64
    %100 = llvm.mlir.zero : !llvm.ptr
    %101 = llvm.getelementptr %100[%99] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %102 = llvm.ptrtoint %101 : !llvm.ptr to i64
    %103 = llvm.call @malloc(%102) : (i64) -> !llvm.ptr
    %104 = llvm.mlir.undef : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
    %105 = llvm.insertvalue %103, %104[0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %106 = llvm.insertvalue %103, %105[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %107 = llvm.mlir.constant(0 : index) : i64
    %108 = llvm.insertvalue %107, %106[2] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %109 = llvm.insertvalue %53, %108[3, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %110 = llvm.insertvalue %47, %109[3, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %111 = llvm.insertvalue %47, %110[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %112 = llvm.insertvalue %98, %111[4, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %113 = llvm.mlir.constant(0 : index) : i64
    %114 = llvm.mlir.constant(0 : index) : i64
    %115 = llvm.mlir.constant(1 : index) : i64
    llvm.br ^bb9(%114 : i64)
  ^bb9(%116: i64):  // 2 preds: ^bb8, ^bb13
    %117 = llvm.icmp "slt" %116, %53 : i64
    llvm.cond_br %117, ^bb10, ^bb14
  ^bb10:  // pred: ^bb9
    %118 = llvm.mlir.constant(0 : index) : i64
    %119 = llvm.mlir.constant(1 : index) : i64
    llvm.br ^bb11(%118 : i64)
  ^bb11(%120: i64):  // 2 preds: ^bb10, ^bb12
    %121 = llvm.icmp "slt" %120, %47 : i64
    llvm.cond_br %121, ^bb12, ^bb13
  ^bb12:  // pred: ^bb11
    %122 = llvm.mul %120, %53  : i64
    %123 = llvm.add %122, %116  : i64
    %124 = llvm.getelementptr %59[%123] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %125 = llvm.load %124 : !llvm.ptr -> f64
    %126 = llvm.mul %116, %47  : i64
    %127 = llvm.add %126, %120  : i64
    %128 = llvm.getelementptr %103[%127] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %125, %128 : f64, !llvm.ptr
    %129 = llvm.add %120, %119  : i64
    llvm.br ^bb11(%129 : i64)
  ^bb13:  // pred: ^bb11
    %130 = llvm.add %116, %115  : i64
    llvm.br ^bb9(%130 : i64)
  ^bb14:  // pred: ^bb9
    llvm.return %112 : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
  ^bb15:  // pred: ^bb0
    %131 = llvm.mlir.addressof @assert_msg : !llvm.ptr
    llvm.call @puts(%131) : (!llvm.ptr) -> ()
    llvm.call @abort() : () -> ()
    llvm.unreachable
  ^bb16:  // pred: ^bb1
    %132 = llvm.mlir.addressof @assert_msg_0 : !llvm.ptr
    llvm.call @puts(%132) : (!llvm.ptr) -> ()
    llvm.call @abort() : () -> ()
    llvm.unreachable
  }
}

