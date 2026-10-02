module {
  llvm.func @malloc(i64) -> !llvm.ptr
  llvm.mlir.global private constant @mg_assert_stderr_msg_1("mg.add: operand shapes differ at runtime in dimension 0\0A") {addr_space = 0 : i32}
  llvm.func @abort()
  llvm.func @write(i32, !llvm.ptr, i64) -> i64
  llvm.mlir.global private constant @mg_assert_stderr_msg_0("mg.add: operand shapes differ at runtime in dimension 1\0A") {addr_space = 0 : i32}
  llvm.func private @printMemrefF64(%arg0: i64, %arg1: !llvm.ptr) attributes {llvm.emit_c_interface, sym_visibility = "private"} {
    %0 = llvm.mlir.undef : !llvm.struct<(i64, ptr)>
    %1 = llvm.insertvalue %arg0, %0[0] : !llvm.struct<(i64, ptr)> 
    %2 = llvm.insertvalue %arg1, %1[1] : !llvm.struct<(i64, ptr)> 
    %3 = llvm.mlir.constant(1 : index) : i64
    %4 = llvm.alloca %3 x !llvm.struct<(i64, ptr)> : (i64) -> !llvm.ptr
    llvm.store %2, %4 : !llvm.struct<(i64, ptr)>, !llvm.ptr
    llvm.call @_mlir_ciface_printMemrefF64(%4) : (!llvm.ptr) -> ()
    llvm.return
  }
  llvm.func @_mlir_ciface_printMemrefF64(!llvm.ptr) attributes {llvm.emit_c_interface, sym_visibility = "private"}
  llvm.func @addt(%arg0: !llvm.ptr, %arg1: !llvm.ptr, %arg2: i64, %arg3: i64, %arg4: i64, %arg5: i64, %arg6: i64, %arg7: !llvm.ptr, %arg8: !llvm.ptr, %arg9: i64, %arg10: i64, %arg11: i64, %arg12: i64, %arg13: i64) -> !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> {
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
    %93 = llvm.mlir.constant(1 : index) : i64
    %94 = llvm.mul %50, %55  : i64
    %95 = llvm.mlir.zero : !llvm.ptr
    %96 = llvm.getelementptr %95[%94] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %97 = llvm.ptrtoint %96 : !llvm.ptr to i64
    %98 = llvm.call @malloc(%97) : (i64) -> !llvm.ptr
    %99 = llvm.mlir.undef : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
    %100 = llvm.insertvalue %98, %99[0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %101 = llvm.insertvalue %98, %100[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %102 = llvm.mlir.constant(0 : index) : i64
    %103 = llvm.insertvalue %102, %101[2] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %104 = llvm.insertvalue %55, %103[3, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %105 = llvm.insertvalue %50, %104[3, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %106 = llvm.insertvalue %50, %105[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %107 = llvm.insertvalue %93, %106[4, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    llvm.br ^bb11(%19 : i64)
  ^bb11(%108: i64):  // 2 preds: ^bb10, ^bb15
    %109 = llvm.icmp "slt" %108, %55 : i64
    llvm.cond_br %109, ^bb12, ^bb16
  ^bb12:  // pred: ^bb11
    llvm.br ^bb13(%19 : i64)
  ^bb13(%110: i64):  // 2 preds: ^bb12, ^bb14
    %111 = llvm.icmp "slt" %110, %50 : i64
    llvm.cond_br %111, ^bb14, ^bb15
  ^bb14:  // pred: ^bb13
    %112 = llvm.mul %110, %55  : i64
    %113 = llvm.add %112, %108  : i64
    %114 = llvm.getelementptr %61[%113] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %115 = llvm.load %114 : !llvm.ptr -> f64
    %116 = llvm.mul %108, %50  : i64
    %117 = llvm.add %116, %110  : i64
    %118 = llvm.getelementptr %98[%117] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %115, %118 : f64, !llvm.ptr
    %119 = llvm.add %110, %18  : i64
    llvm.br ^bb13(%119 : i64)
  ^bb15:  // pred: ^bb13
    %120 = llvm.add %108, %18  : i64
    llvm.br ^bb11(%120 : i64)
  ^bb16:  // pred: ^bb11
    llvm.return %107 : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
  }
  llvm.func @main() -> i32 {
    %0 = llvm.mlir.constant(0 : i32) : i32
    %1 = llvm.mlir.constant(5.000000e-01 : f64) : f64
    %2 = llvm.mlir.constant(6.000000e+01 : f64) : f64
    %3 = llvm.mlir.constant(5.000000e+01 : f64) : f64
    %4 = llvm.mlir.constant(4.000000e+01 : f64) : f64
    %5 = llvm.mlir.constant(3.000000e+01 : f64) : f64
    %6 = llvm.mlir.constant(2.000000e+01 : f64) : f64
    %7 = llvm.mlir.constant(1.000000e+01 : f64) : f64
    %8 = llvm.mlir.constant(6.000000e+00 : f64) : f64
    %9 = llvm.mlir.constant(5.000000e+00 : f64) : f64
    %10 = llvm.mlir.constant(4.000000e+00 : f64) : f64
    %11 = llvm.mlir.constant(2 : index) : i64
    %12 = llvm.mlir.constant(3.000000e+00 : f64) : f64
    %13 = llvm.mlir.constant(1 : index) : i64
    %14 = llvm.mlir.constant(2.000000e+00 : f64) : f64
    %15 = llvm.mlir.constant(0 : index) : i64
    %16 = llvm.mlir.constant(1.000000e+00 : f64) : f64
    %17 = llvm.mlir.constant(2 : index) : i64
    %18 = llvm.mlir.constant(3 : index) : i64
    %19 = llvm.mlir.constant(1 : index) : i64
    %20 = llvm.mlir.constant(6 : index) : i64
    %21 = llvm.mlir.zero : !llvm.ptr
    %22 = llvm.getelementptr %21[6] : (!llvm.ptr) -> !llvm.ptr, f64
    %23 = llvm.ptrtoint %22 : !llvm.ptr to i64
    %24 = llvm.call @malloc(%23) : (i64) -> !llvm.ptr
    %25 = llvm.mlir.undef : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
    %26 = llvm.insertvalue %24, %25[0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %27 = llvm.insertvalue %24, %26[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %28 = llvm.mlir.constant(0 : index) : i64
    %29 = llvm.insertvalue %28, %27[2] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %30 = llvm.insertvalue %17, %29[3, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %31 = llvm.insertvalue %18, %30[3, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %32 = llvm.insertvalue %18, %31[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %33 = llvm.insertvalue %19, %32[4, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %34 = llvm.mlir.constant(3 : index) : i64
    %35 = llvm.mul %15, %34  : i64
    %36 = llvm.add %35, %15  : i64
    %37 = llvm.getelementptr %24[%36] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %16, %37 : f64, !llvm.ptr
    %38 = llvm.mlir.constant(3 : index) : i64
    %39 = llvm.mul %15, %38  : i64
    %40 = llvm.add %39, %13  : i64
    %41 = llvm.getelementptr %24[%40] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %14, %41 : f64, !llvm.ptr
    %42 = llvm.mlir.constant(3 : index) : i64
    %43 = llvm.mul %15, %42  : i64
    %44 = llvm.add %43, %11  : i64
    %45 = llvm.getelementptr %24[%44] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %12, %45 : f64, !llvm.ptr
    %46 = llvm.mlir.constant(3 : index) : i64
    %47 = llvm.mul %13, %46  : i64
    %48 = llvm.add %47, %15  : i64
    %49 = llvm.getelementptr %24[%48] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %10, %49 : f64, !llvm.ptr
    %50 = llvm.mlir.constant(3 : index) : i64
    %51 = llvm.mul %13, %50  : i64
    %52 = llvm.add %51, %13  : i64
    %53 = llvm.getelementptr %24[%52] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %9, %53 : f64, !llvm.ptr
    %54 = llvm.mlir.constant(3 : index) : i64
    %55 = llvm.mul %13, %54  : i64
    %56 = llvm.add %55, %11  : i64
    %57 = llvm.getelementptr %24[%56] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %8, %57 : f64, !llvm.ptr
    %58 = llvm.mlir.constant(2 : index) : i64
    %59 = llvm.mlir.constant(3 : index) : i64
    %60 = llvm.mlir.constant(1 : index) : i64
    %61 = llvm.mlir.constant(6 : index) : i64
    %62 = llvm.mlir.zero : !llvm.ptr
    %63 = llvm.getelementptr %62[6] : (!llvm.ptr) -> !llvm.ptr, f64
    %64 = llvm.ptrtoint %63 : !llvm.ptr to i64
    %65 = llvm.call @malloc(%64) : (i64) -> !llvm.ptr
    %66 = llvm.mlir.undef : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
    %67 = llvm.insertvalue %65, %66[0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %68 = llvm.insertvalue %65, %67[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %69 = llvm.mlir.constant(0 : index) : i64
    %70 = llvm.insertvalue %69, %68[2] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %71 = llvm.insertvalue %58, %70[3, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %72 = llvm.insertvalue %59, %71[3, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %73 = llvm.insertvalue %59, %72[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %74 = llvm.insertvalue %60, %73[4, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %75 = llvm.mlir.constant(3 : index) : i64
    %76 = llvm.mul %15, %75  : i64
    %77 = llvm.add %76, %15  : i64
    %78 = llvm.getelementptr %65[%77] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %7, %78 : f64, !llvm.ptr
    %79 = llvm.mlir.constant(3 : index) : i64
    %80 = llvm.mul %15, %79  : i64
    %81 = llvm.add %80, %13  : i64
    %82 = llvm.getelementptr %65[%81] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %6, %82 : f64, !llvm.ptr
    %83 = llvm.mlir.constant(3 : index) : i64
    %84 = llvm.mul %15, %83  : i64
    %85 = llvm.add %84, %11  : i64
    %86 = llvm.getelementptr %65[%85] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %5, %86 : f64, !llvm.ptr
    %87 = llvm.mlir.constant(3 : index) : i64
    %88 = llvm.mul %13, %87  : i64
    %89 = llvm.add %88, %15  : i64
    %90 = llvm.getelementptr %65[%89] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %4, %90 : f64, !llvm.ptr
    %91 = llvm.mlir.constant(3 : index) : i64
    %92 = llvm.mul %13, %91  : i64
    %93 = llvm.add %92, %13  : i64
    %94 = llvm.getelementptr %65[%93] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %3, %94 : f64, !llvm.ptr
    %95 = llvm.mlir.constant(3 : index) : i64
    %96 = llvm.mul %13, %95  : i64
    %97 = llvm.add %96, %11  : i64
    %98 = llvm.getelementptr %65[%97] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %2, %98 : f64, !llvm.ptr
    %99 = llvm.call @addt(%24, %24, %28, %17, %18, %18, %19, %65, %65, %69, %58, %59, %59, %60) : (!llvm.ptr, !llvm.ptr, i64, i64, i64, i64, i64, !llvm.ptr, !llvm.ptr, i64, i64, i64, i64, i64) -> !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
    %100 = llvm.mlir.constant(1 : index) : i64
    %101 = llvm.alloca %100 x !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> : (i64) -> !llvm.ptr
    llvm.store %99, %101 : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>, !llvm.ptr
    %102 = llvm.mlir.constant(2 : index) : i64
    %103 = llvm.mlir.undef : !llvm.struct<(i64, ptr)>
    %104 = llvm.insertvalue %102, %103[0] : !llvm.struct<(i64, ptr)> 
    %105 = llvm.insertvalue %101, %104[1] : !llvm.struct<(i64, ptr)> 
    llvm.call @printMemrefF64(%102, %101) : (i64, !llvm.ptr) -> ()
    %106 = llvm.mlir.constant(3 : index) : i64
    %107 = llvm.mlir.constant(1 : index) : i64
    %108 = llvm.mlir.constant(1 : index) : i64
    %109 = llvm.mlir.zero : !llvm.ptr
    %110 = llvm.getelementptr %109[3] : (!llvm.ptr) -> !llvm.ptr, f64
    %111 = llvm.ptrtoint %110 : !llvm.ptr to i64
    %112 = llvm.call @malloc(%111) : (i64) -> !llvm.ptr
    %113 = llvm.mlir.undef : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
    %114 = llvm.insertvalue %112, %113[0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %115 = llvm.insertvalue %112, %114[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %116 = llvm.mlir.constant(0 : index) : i64
    %117 = llvm.insertvalue %116, %115[2] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %118 = llvm.insertvalue %106, %117[3, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %119 = llvm.insertvalue %107, %118[3, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %120 = llvm.insertvalue %107, %119[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %121 = llvm.insertvalue %108, %120[4, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %122 = llvm.add %15, %15  : i64
    %123 = llvm.getelementptr %112[%122] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %16, %123 : f64, !llvm.ptr
    %124 = llvm.add %13, %15  : i64
    %125 = llvm.getelementptr %112[%124] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %14, %125 : f64, !llvm.ptr
    %126 = llvm.add %11, %15  : i64
    %127 = llvm.getelementptr %112[%126] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %12, %127 : f64, !llvm.ptr
    %128 = llvm.mlir.constant(3 : index) : i64
    %129 = llvm.mlir.constant(1 : index) : i64
    %130 = llvm.mlir.constant(1 : index) : i64
    %131 = llvm.mlir.zero : !llvm.ptr
    %132 = llvm.getelementptr %131[3] : (!llvm.ptr) -> !llvm.ptr, f64
    %133 = llvm.ptrtoint %132 : !llvm.ptr to i64
    %134 = llvm.call @malloc(%133) : (i64) -> !llvm.ptr
    %135 = llvm.mlir.undef : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
    %136 = llvm.insertvalue %134, %135[0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %137 = llvm.insertvalue %134, %136[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %138 = llvm.mlir.constant(0 : index) : i64
    %139 = llvm.insertvalue %138, %137[2] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %140 = llvm.insertvalue %128, %139[3, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %141 = llvm.insertvalue %129, %140[3, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %142 = llvm.insertvalue %129, %141[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %143 = llvm.insertvalue %130, %142[4, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %144 = llvm.add %15, %15  : i64
    %145 = llvm.getelementptr %134[%144] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %1, %145 : f64, !llvm.ptr
    %146 = llvm.add %13, %15  : i64
    %147 = llvm.getelementptr %134[%146] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %1, %147 : f64, !llvm.ptr
    %148 = llvm.add %11, %15  : i64
    %149 = llvm.getelementptr %134[%148] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %1, %149 : f64, !llvm.ptr
    %150 = llvm.call @addt(%112, %112, %116, %106, %107, %107, %108, %134, %134, %138, %128, %129, %129, %130) : (!llvm.ptr, !llvm.ptr, i64, i64, i64, i64, i64, !llvm.ptr, !llvm.ptr, i64, i64, i64, i64, i64) -> !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
    %151 = llvm.mlir.constant(1 : index) : i64
    %152 = llvm.alloca %151 x !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> : (i64) -> !llvm.ptr
    llvm.store %150, %152 : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>, !llvm.ptr
    %153 = llvm.mlir.constant(2 : index) : i64
    %154 = llvm.mlir.undef : !llvm.struct<(i64, ptr)>
    %155 = llvm.insertvalue %153, %154[0] : !llvm.struct<(i64, ptr)> 
    %156 = llvm.insertvalue %152, %155[1] : !llvm.struct<(i64, ptr)> 
    llvm.call @printMemrefF64(%153, %152) : (i64, !llvm.ptr) -> ()
    llvm.return %0 : i32
  }
}

