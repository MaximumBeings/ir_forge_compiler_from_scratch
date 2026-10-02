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
    llvm.cond_br %28, ^bb1, ^bb27
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
    llvm.cond_br %41, ^bb2, ^bb28
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
    %71 = llvm.mlir.constant(2 : index) : i64
    llvm.br ^bb3(%70 : i64)
  ^bb3(%72: i64):  // 2 preds: ^bb2, ^bb13
    %73 = llvm.icmp "slt" %72, %47 : i64
    llvm.cond_br %73, ^bb4, ^bb14
  ^bb4:  // pred: ^bb3
    %74 = llvm.mlir.constant(0 : index) : i64
    %75 = llvm.mlir.constant(2 : index) : i64
    llvm.br ^bb5(%74 : i64)
  ^bb5(%76: i64):  // 2 preds: ^bb4, ^bb12
    %77 = llvm.icmp "slt" %76, %53 : i64
    llvm.cond_br %77, ^bb6, ^bb13
  ^bb6:  // pred: ^bb5
    %78 = llvm.mlir.constant(2 : index) : i64
    %79 = llvm.add %72, %78  : i64
    %80 = llvm.icmp "slt" %79, %47 : i64
    %81 = llvm.select %80, %79, %47 : i1, i64
    %82 = llvm.mlir.constant(1 : index) : i64
    llvm.br ^bb7(%72 : i64)
  ^bb7(%83: i64):  // 2 preds: ^bb6, ^bb11
    %84 = llvm.icmp "slt" %83, %81 : i64
    llvm.cond_br %84, ^bb8, ^bb12
  ^bb8:  // pred: ^bb7
    %85 = llvm.mlir.constant(2 : index) : i64
    %86 = llvm.add %76, %85  : i64
    %87 = llvm.icmp "slt" %86, %53 : i64
    %88 = llvm.select %87, %86, %53 : i1, i64
    %89 = llvm.mlir.constant(1 : index) : i64
    llvm.br ^bb9(%76 : i64)
  ^bb9(%90: i64):  // 2 preds: ^bb8, ^bb10
    %91 = llvm.icmp "slt" %90, %88 : i64
    llvm.cond_br %91, ^bb10, ^bb11
  ^bb10:  // pred: ^bb9
    %92 = llvm.extractvalue %7[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %93 = llvm.extractvalue %7[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %94 = llvm.mul %83, %93  : i64
    %95 = llvm.add %94, %90  : i64
    %96 = llvm.getelementptr %92[%95] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %97 = llvm.load %96 : !llvm.ptr -> f64
    %98 = llvm.extractvalue %15[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %99 = llvm.extractvalue %15[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %100 = llvm.mul %83, %99  : i64
    %101 = llvm.add %100, %90  : i64
    %102 = llvm.getelementptr %98[%101] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %103 = llvm.load %102 : !llvm.ptr -> f64
    %104 = llvm.fadd %97, %103  : f64
    %105 = llvm.mul %83, %53  : i64
    %106 = llvm.add %105, %90  : i64
    %107 = llvm.getelementptr %59[%106] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %104, %107 : f64, !llvm.ptr
    %108 = llvm.add %90, %89  : i64
    llvm.br ^bb9(%108 : i64)
  ^bb11:  // pred: ^bb9
    %109 = llvm.add %83, %82  : i64
    llvm.br ^bb7(%109 : i64)
  ^bb12:  // pred: ^bb7
    %110 = llvm.add %76, %75  : i64
    llvm.br ^bb5(%110 : i64)
  ^bb13:  // pred: ^bb5
    %111 = llvm.add %72, %71  : i64
    llvm.br ^bb3(%111 : i64)
  ^bb14:  // pred: ^bb3
    %112 = llvm.mlir.constant(1 : index) : i64
    %113 = llvm.mlir.constant(0 : index) : i64
    %114 = llvm.mlir.constant(1 : index) : i64
    %115 = llvm.mul %47, %53  : i64
    %116 = llvm.mlir.zero : !llvm.ptr
    %117 = llvm.getelementptr %116[%115] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %118 = llvm.ptrtoint %117 : !llvm.ptr to i64
    %119 = llvm.call @malloc(%118) : (i64) -> !llvm.ptr
    %120 = llvm.mlir.undef : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
    %121 = llvm.insertvalue %119, %120[0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %122 = llvm.insertvalue %119, %121[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %123 = llvm.mlir.constant(0 : index) : i64
    %124 = llvm.insertvalue %123, %122[2] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %125 = llvm.insertvalue %53, %124[3, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %126 = llvm.insertvalue %47, %125[3, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %127 = llvm.insertvalue %47, %126[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %128 = llvm.insertvalue %114, %127[4, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %129 = llvm.mlir.constant(0 : index) : i64
    %130 = llvm.mlir.constant(0 : index) : i64
    %131 = llvm.mlir.constant(2 : index) : i64
    llvm.br ^bb15(%130 : i64)
  ^bb15(%132: i64):  // 2 preds: ^bb14, ^bb25
    %133 = llvm.icmp "slt" %132, %53 : i64
    llvm.cond_br %133, ^bb16, ^bb26
  ^bb16:  // pred: ^bb15
    %134 = llvm.mlir.constant(0 : index) : i64
    %135 = llvm.mlir.constant(2 : index) : i64
    llvm.br ^bb17(%134 : i64)
  ^bb17(%136: i64):  // 2 preds: ^bb16, ^bb24
    %137 = llvm.icmp "slt" %136, %47 : i64
    llvm.cond_br %137, ^bb18, ^bb25
  ^bb18:  // pred: ^bb17
    %138 = llvm.mlir.constant(2 : index) : i64
    %139 = llvm.add %132, %138  : i64
    %140 = llvm.icmp "slt" %139, %53 : i64
    %141 = llvm.select %140, %139, %53 : i1, i64
    %142 = llvm.mlir.constant(1 : index) : i64
    llvm.br ^bb19(%132 : i64)
  ^bb19(%143: i64):  // 2 preds: ^bb18, ^bb23
    %144 = llvm.icmp "slt" %143, %141 : i64
    llvm.cond_br %144, ^bb20, ^bb24
  ^bb20:  // pred: ^bb19
    %145 = llvm.mlir.constant(2 : index) : i64
    %146 = llvm.add %136, %145  : i64
    %147 = llvm.icmp "slt" %146, %47 : i64
    %148 = llvm.select %147, %146, %47 : i1, i64
    %149 = llvm.mlir.constant(1 : index) : i64
    llvm.br ^bb21(%136 : i64)
  ^bb21(%150: i64):  // 2 preds: ^bb20, ^bb22
    %151 = llvm.icmp "slt" %150, %148 : i64
    llvm.cond_br %151, ^bb22, ^bb23
  ^bb22:  // pred: ^bb21
    %152 = llvm.mul %150, %53  : i64
    %153 = llvm.add %152, %143  : i64
    %154 = llvm.getelementptr %59[%153] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %155 = llvm.load %154 : !llvm.ptr -> f64
    %156 = llvm.mul %143, %47  : i64
    %157 = llvm.add %156, %150  : i64
    %158 = llvm.getelementptr %119[%157] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %155, %158 : f64, !llvm.ptr
    %159 = llvm.add %150, %149  : i64
    llvm.br ^bb21(%159 : i64)
  ^bb23:  // pred: ^bb21
    %160 = llvm.add %143, %142  : i64
    llvm.br ^bb19(%160 : i64)
  ^bb24:  // pred: ^bb19
    %161 = llvm.add %136, %135  : i64
    llvm.br ^bb17(%161 : i64)
  ^bb25:  // pred: ^bb17
    %162 = llvm.add %132, %131  : i64
    llvm.br ^bb15(%162 : i64)
  ^bb26:  // pred: ^bb15
    llvm.return %128 : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
  ^bb27:  // pred: ^bb0
    %163 = llvm.mlir.addressof @assert_msg : !llvm.ptr
    llvm.call @puts(%163) : (!llvm.ptr) -> ()
    llvm.call @abort() : () -> ()
    llvm.unreachable
  ^bb28:  // pred: ^bb1
    %164 = llvm.mlir.addressof @assert_msg_0 : !llvm.ptr
    llvm.call @puts(%164) : (!llvm.ptr) -> ()
    llvm.call @abort() : () -> ()
    llvm.unreachable
  }
}

