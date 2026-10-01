module {
  llvm.func @malloc(i64) -> !llvm.ptr
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
  llvm.func @add_tensors(%arg0: !llvm.ptr, %arg1: !llvm.ptr, %arg2: i64, %arg3: i64, %arg4: i64, %arg5: i64, %arg6: i64, %arg7: !llvm.ptr, %arg8: !llvm.ptr, %arg9: i64, %arg10: i64, %arg11: i64, %arg12: i64, %arg13: i64) {
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
    %44 = llvm.mlir.constant(2 : index) : i64
    %45 = llvm.mul %36, %44  : i64
    %46 = llvm.add %45, %41  : i64
    %47 = llvm.getelementptr %43[%46] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %48 = llvm.load %47 : !llvm.ptr -> f64
    %49 = llvm.extractvalue %15[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %50 = llvm.mlir.constant(2 : index) : i64
    %51 = llvm.mul %36, %50  : i64
    %52 = llvm.add %51, %41  : i64
    %53 = llvm.getelementptr %49[%52] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %54 = llvm.load %53 : !llvm.ptr -> f64
    %55 = llvm.fadd %48, %54  : f64
    %56 = llvm.mlir.constant(2 : index) : i64
    %57 = llvm.mul %36, %56  : i64
    %58 = llvm.add %57, %41  : i64
    %59 = llvm.getelementptr %23[%58] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %55, %59 : f64, !llvm.ptr
    %60 = llvm.add %41, %40  : i64
    llvm.br ^bb3(%60 : i64)
  ^bb5:  // pred: ^bb3
    %61 = llvm.add %36, %35  : i64
    llvm.br ^bb1(%61 : i64)
  ^bb6:  // pred: ^bb1
    %62 = llvm.mlir.constant(1 : index) : i64
    %63 = llvm.alloca %62 x !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> : (i64) -> !llvm.ptr
    llvm.store %32, %63 : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>, !llvm.ptr
    %64 = llvm.mlir.constant(2 : index) : i64
    %65 = llvm.mlir.undef : !llvm.struct<(i64, ptr)>
    %66 = llvm.insertvalue %64, %65[0] : !llvm.struct<(i64, ptr)> 
    %67 = llvm.insertvalue %63, %66[1] : !llvm.struct<(i64, ptr)> 
    llvm.call @printMemrefF64(%64, %63) : (i64, !llvm.ptr) -> ()
    llvm.return
  }
  llvm.func @main() {
    %0 = llvm.mlir.constant(2 : index) : i64
    %1 = llvm.mlir.constant(2 : index) : i64
    %2 = llvm.mlir.constant(1 : index) : i64
    %3 = llvm.mlir.constant(4 : index) : i64
    %4 = llvm.mlir.zero : !llvm.ptr
    %5 = llvm.getelementptr %4[4] : (!llvm.ptr) -> !llvm.ptr, f64
    %6 = llvm.ptrtoint %5 : !llvm.ptr to i64
    %7 = llvm.call @malloc(%6) : (i64) -> !llvm.ptr
    %8 = llvm.mlir.undef : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
    %9 = llvm.insertvalue %7, %8[0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %10 = llvm.insertvalue %7, %9[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %11 = llvm.mlir.constant(0 : index) : i64
    %12 = llvm.insertvalue %11, %10[2] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %13 = llvm.insertvalue %0, %12[3, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %14 = llvm.insertvalue %1, %13[3, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %15 = llvm.insertvalue %1, %14[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %16 = llvm.insertvalue %2, %15[4, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %17 = llvm.mlir.constant(1.000000e+00 : f64) : f64
    %18 = llvm.mlir.constant(0 : index) : i64
    %19 = llvm.mlir.constant(0 : index) : i64
    %20 = llvm.mlir.constant(2 : index) : i64
    %21 = llvm.mul %18, %20  : i64
    %22 = llvm.add %21, %19  : i64
    %23 = llvm.getelementptr %7[%22] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %17, %23 : f64, !llvm.ptr
    %24 = llvm.mlir.constant(2.000000e+00 : f64) : f64
    %25 = llvm.mlir.constant(0 : index) : i64
    %26 = llvm.mlir.constant(1 : index) : i64
    %27 = llvm.mlir.constant(2 : index) : i64
    %28 = llvm.mul %25, %27  : i64
    %29 = llvm.add %28, %26  : i64
    %30 = llvm.getelementptr %7[%29] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %24, %30 : f64, !llvm.ptr
    %31 = llvm.mlir.constant(3.000000e+00 : f64) : f64
    %32 = llvm.mlir.constant(1 : index) : i64
    %33 = llvm.mlir.constant(0 : index) : i64
    %34 = llvm.mlir.constant(2 : index) : i64
    %35 = llvm.mul %32, %34  : i64
    %36 = llvm.add %35, %33  : i64
    %37 = llvm.getelementptr %7[%36] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %31, %37 : f64, !llvm.ptr
    %38 = llvm.mlir.constant(4.000000e+00 : f64) : f64
    %39 = llvm.mlir.constant(1 : index) : i64
    %40 = llvm.mlir.constant(1 : index) : i64
    %41 = llvm.mlir.constant(2 : index) : i64
    %42 = llvm.mul %39, %41  : i64
    %43 = llvm.add %42, %40  : i64
    %44 = llvm.getelementptr %7[%43] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %38, %44 : f64, !llvm.ptr
    %45 = llvm.mlir.constant(2 : index) : i64
    %46 = llvm.mlir.constant(2 : index) : i64
    %47 = llvm.mlir.constant(1 : index) : i64
    %48 = llvm.mlir.constant(4 : index) : i64
    %49 = llvm.mlir.zero : !llvm.ptr
    %50 = llvm.getelementptr %49[4] : (!llvm.ptr) -> !llvm.ptr, f64
    %51 = llvm.ptrtoint %50 : !llvm.ptr to i64
    %52 = llvm.call @malloc(%51) : (i64) -> !llvm.ptr
    %53 = llvm.mlir.undef : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
    %54 = llvm.insertvalue %52, %53[0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %55 = llvm.insertvalue %52, %54[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %56 = llvm.mlir.constant(0 : index) : i64
    %57 = llvm.insertvalue %56, %55[2] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %58 = llvm.insertvalue %45, %57[3, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %59 = llvm.insertvalue %46, %58[3, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %60 = llvm.insertvalue %46, %59[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %61 = llvm.insertvalue %47, %60[4, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %62 = llvm.mlir.constant(5.000000e+00 : f64) : f64
    %63 = llvm.mlir.constant(0 : index) : i64
    %64 = llvm.mlir.constant(0 : index) : i64
    %65 = llvm.mlir.constant(2 : index) : i64
    %66 = llvm.mul %63, %65  : i64
    %67 = llvm.add %66, %64  : i64
    %68 = llvm.getelementptr %52[%67] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %62, %68 : f64, !llvm.ptr
    %69 = llvm.mlir.constant(6.000000e+00 : f64) : f64
    %70 = llvm.mlir.constant(0 : index) : i64
    %71 = llvm.mlir.constant(1 : index) : i64
    %72 = llvm.mlir.constant(2 : index) : i64
    %73 = llvm.mul %70, %72  : i64
    %74 = llvm.add %73, %71  : i64
    %75 = llvm.getelementptr %52[%74] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %69, %75 : f64, !llvm.ptr
    %76 = llvm.mlir.constant(7.000000e+00 : f64) : f64
    %77 = llvm.mlir.constant(1 : index) : i64
    %78 = llvm.mlir.constant(0 : index) : i64
    %79 = llvm.mlir.constant(2 : index) : i64
    %80 = llvm.mul %77, %79  : i64
    %81 = llvm.add %80, %78  : i64
    %82 = llvm.getelementptr %52[%81] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %76, %82 : f64, !llvm.ptr
    %83 = llvm.mlir.constant(8.000000e+00 : f64) : f64
    %84 = llvm.mlir.constant(1 : index) : i64
    %85 = llvm.mlir.constant(1 : index) : i64
    %86 = llvm.mlir.constant(2 : index) : i64
    %87 = llvm.mul %84, %86  : i64
    %88 = llvm.add %87, %85  : i64
    %89 = llvm.getelementptr %52[%88] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %83, %89 : f64, !llvm.ptr
    llvm.call @add_tensors(%7, %7, %11, %0, %1, %1, %2, %52, %52, %56, %45, %46, %46, %47) : (!llvm.ptr, !llvm.ptr, i64, i64, i64, i64, i64, !llvm.ptr, !llvm.ptr, i64, i64, i64, i64, i64) -> ()
    llvm.return
  }
}

