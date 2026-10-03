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
  llvm.func @scale_add(%arg0: !llvm.ptr, %arg1: !llvm.ptr, %arg2: i64, %arg3: i64, %arg4: i64, %arg5: i64, %arg6: i64, %arg7: !llvm.ptr, %arg8: !llvm.ptr, %arg9: i64, %arg10: i64, %arg11: i64, %arg12: i64, %arg13: i64) -> !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> {
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
    %16 = llvm.mlir.constant(3 : index) : i64
    %17 = llvm.mlir.constant(1 : index) : i64
    %18 = llvm.mlir.constant(0 : index) : i64
    %19 = llvm.mlir.constant(2.000000e+00 : f64) : f64
    %20 = llvm.mlir.constant(1 : index) : i64
    %21 = llvm.mlir.constant(3 : index) : i64
    %22 = llvm.mlir.constant(1 : index) : i64
    %23 = llvm.mlir.constant(3 : index) : i64
    %24 = llvm.mlir.zero : !llvm.ptr
    %25 = llvm.getelementptr %24[3] : (!llvm.ptr) -> !llvm.ptr, f64
    %26 = llvm.ptrtoint %25 : !llvm.ptr to i64
    %27 = llvm.call @malloc(%26) : (i64) -> !llvm.ptr
    %28 = llvm.mlir.undef : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
    %29 = llvm.insertvalue %27, %28[0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %30 = llvm.insertvalue %27, %29[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %31 = llvm.mlir.constant(0 : index) : i64
    %32 = llvm.insertvalue %31, %30[2] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %33 = llvm.insertvalue %20, %32[3, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %34 = llvm.insertvalue %21, %33[3, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %35 = llvm.insertvalue %21, %34[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %36 = llvm.insertvalue %22, %35[4, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    llvm.br ^bb1(%18 : i64)
  ^bb1(%37: i64):  // 2 preds: ^bb0, ^bb5
    %38 = llvm.icmp "slt" %37, %17 : i64
    llvm.cond_br %38, ^bb2, ^bb6
  ^bb2:  // pred: ^bb1
    llvm.br ^bb3(%18 : i64)
  ^bb3(%39: i64):  // 2 preds: ^bb2, ^bb4
    %40 = llvm.icmp "slt" %39, %16 : i64
    llvm.cond_br %40, ^bb4, ^bb5
  ^bb4:  // pred: ^bb3
    %41 = llvm.extractvalue %7[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %42 = llvm.mlir.constant(3 : index) : i64
    %43 = llvm.mul %37, %42  : i64
    %44 = llvm.add %43, %39  : i64
    %45 = llvm.getelementptr %41[%44] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %46 = llvm.load %45 : !llvm.ptr -> f64
    %47 = llvm.fmul %46, %19  : f64
    %48 = llvm.mlir.constant(3 : index) : i64
    %49 = llvm.mul %37, %48  : i64
    %50 = llvm.add %49, %39  : i64
    %51 = llvm.getelementptr %27[%50] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %47, %51 : f64, !llvm.ptr
    %52 = llvm.add %39, %17  : i64
    llvm.br ^bb3(%52 : i64)
  ^bb5:  // pred: ^bb3
    %53 = llvm.add %37, %17  : i64
    llvm.br ^bb1(%53 : i64)
  ^bb6:  // pred: ^bb1
    %54 = llvm.mlir.constant(1 : index) : i64
    %55 = llvm.mlir.constant(3 : index) : i64
    %56 = llvm.mlir.constant(1 : index) : i64
    %57 = llvm.mlir.constant(3 : index) : i64
    %58 = llvm.mlir.zero : !llvm.ptr
    %59 = llvm.getelementptr %58[3] : (!llvm.ptr) -> !llvm.ptr, f64
    %60 = llvm.ptrtoint %59 : !llvm.ptr to i64
    %61 = llvm.call @malloc(%60) : (i64) -> !llvm.ptr
    %62 = llvm.mlir.undef : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
    %63 = llvm.insertvalue %61, %62[0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %64 = llvm.insertvalue %61, %63[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %65 = llvm.mlir.constant(0 : index) : i64
    %66 = llvm.insertvalue %65, %64[2] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %67 = llvm.insertvalue %54, %66[3, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %68 = llvm.insertvalue %55, %67[3, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %69 = llvm.insertvalue %55, %68[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %70 = llvm.insertvalue %56, %69[4, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    llvm.br ^bb7(%18 : i64)
  ^bb7(%71: i64):  // 2 preds: ^bb6, ^bb11
    %72 = llvm.icmp "slt" %71, %17 : i64
    llvm.cond_br %72, ^bb8, ^bb12
  ^bb8:  // pred: ^bb7
    llvm.br ^bb9(%18 : i64)
  ^bb9(%73: i64):  // 2 preds: ^bb8, ^bb10
    %74 = llvm.icmp "slt" %73, %16 : i64
    llvm.cond_br %74, ^bb10, ^bb11
  ^bb10:  // pred: ^bb9
    %75 = llvm.mlir.constant(3 : index) : i64
    %76 = llvm.mul %71, %75  : i64
    %77 = llvm.add %76, %73  : i64
    %78 = llvm.getelementptr %27[%77] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %79 = llvm.load %78 : !llvm.ptr -> f64
    %80 = llvm.extractvalue %15[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %81 = llvm.mlir.constant(3 : index) : i64
    %82 = llvm.mul %71, %81  : i64
    %83 = llvm.add %82, %73  : i64
    %84 = llvm.getelementptr %80[%83] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    %85 = llvm.load %84 : !llvm.ptr -> f64
    %86 = llvm.fadd %79, %85  : f64
    %87 = llvm.mlir.constant(3 : index) : i64
    %88 = llvm.mul %71, %87  : i64
    %89 = llvm.add %88, %73  : i64
    %90 = llvm.getelementptr %61[%89] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %86, %90 : f64, !llvm.ptr
    %91 = llvm.add %73, %17  : i64
    llvm.br ^bb9(%91 : i64)
  ^bb11:  // pred: ^bb9
    %92 = llvm.add %71, %17  : i64
    llvm.br ^bb7(%92 : i64)
  ^bb12:  // pred: ^bb7
    llvm.return %70 : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
  }
  llvm.func @main() -> i32 {
    %0 = llvm.mlir.constant(0 : i32) : i32
    %1 = llvm.mlir.constant(3.000000e+01 : f64) : f64
    %2 = llvm.mlir.constant(2.000000e+01 : f64) : f64
    %3 = llvm.mlir.constant(1.000000e+01 : f64) : f64
    %4 = llvm.mlir.constant(2 : index) : i64
    %5 = llvm.mlir.constant(3.000000e+00 : f64) : f64
    %6 = llvm.mlir.constant(1 : index) : i64
    %7 = llvm.mlir.constant(2.000000e+00 : f64) : f64
    %8 = llvm.mlir.constant(0 : index) : i64
    %9 = llvm.mlir.constant(1.000000e+00 : f64) : f64
    %10 = llvm.mlir.constant(1 : index) : i64
    %11 = llvm.mlir.constant(3 : index) : i64
    %12 = llvm.mlir.constant(1 : index) : i64
    %13 = llvm.mlir.constant(3 : index) : i64
    %14 = llvm.mlir.zero : !llvm.ptr
    %15 = llvm.getelementptr %14[3] : (!llvm.ptr) -> !llvm.ptr, f64
    %16 = llvm.ptrtoint %15 : !llvm.ptr to i64
    %17 = llvm.call @malloc(%16) : (i64) -> !llvm.ptr
    %18 = llvm.mlir.undef : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
    %19 = llvm.insertvalue %17, %18[0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %20 = llvm.insertvalue %17, %19[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %21 = llvm.mlir.constant(0 : index) : i64
    %22 = llvm.insertvalue %21, %20[2] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %23 = llvm.insertvalue %10, %22[3, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %24 = llvm.insertvalue %11, %23[3, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %25 = llvm.insertvalue %11, %24[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %26 = llvm.insertvalue %12, %25[4, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %27 = llvm.mlir.constant(3 : index) : i64
    %28 = llvm.mul %8, %27  : i64
    %29 = llvm.add %28, %8  : i64
    %30 = llvm.getelementptr %17[%29] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %9, %30 : f64, !llvm.ptr
    %31 = llvm.mlir.constant(3 : index) : i64
    %32 = llvm.mul %8, %31  : i64
    %33 = llvm.add %32, %6  : i64
    %34 = llvm.getelementptr %17[%33] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %7, %34 : f64, !llvm.ptr
    %35 = llvm.mlir.constant(3 : index) : i64
    %36 = llvm.mul %8, %35  : i64
    %37 = llvm.add %36, %4  : i64
    %38 = llvm.getelementptr %17[%37] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %5, %38 : f64, !llvm.ptr
    %39 = llvm.mlir.constant(1 : index) : i64
    %40 = llvm.mlir.constant(3 : index) : i64
    %41 = llvm.mlir.constant(1 : index) : i64
    %42 = llvm.mlir.constant(3 : index) : i64
    %43 = llvm.mlir.zero : !llvm.ptr
    %44 = llvm.getelementptr %43[3] : (!llvm.ptr) -> !llvm.ptr, f64
    %45 = llvm.ptrtoint %44 : !llvm.ptr to i64
    %46 = llvm.call @malloc(%45) : (i64) -> !llvm.ptr
    %47 = llvm.mlir.undef : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
    %48 = llvm.insertvalue %46, %47[0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %49 = llvm.insertvalue %46, %48[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %50 = llvm.mlir.constant(0 : index) : i64
    %51 = llvm.insertvalue %50, %49[2] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %52 = llvm.insertvalue %39, %51[3, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %53 = llvm.insertvalue %40, %52[3, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %54 = llvm.insertvalue %40, %53[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %55 = llvm.insertvalue %41, %54[4, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
    %56 = llvm.mlir.constant(3 : index) : i64
    %57 = llvm.mul %8, %56  : i64
    %58 = llvm.add %57, %8  : i64
    %59 = llvm.getelementptr %46[%58] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %3, %59 : f64, !llvm.ptr
    %60 = llvm.mlir.constant(3 : index) : i64
    %61 = llvm.mul %8, %60  : i64
    %62 = llvm.add %61, %6  : i64
    %63 = llvm.getelementptr %46[%62] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %2, %63 : f64, !llvm.ptr
    %64 = llvm.mlir.constant(3 : index) : i64
    %65 = llvm.mul %8, %64  : i64
    %66 = llvm.add %65, %4  : i64
    %67 = llvm.getelementptr %46[%66] : (!llvm.ptr, i64) -> !llvm.ptr, f64
    llvm.store %1, %67 : f64, !llvm.ptr
    %68 = llvm.call @scale_add(%17, %17, %21, %10, %11, %11, %12, %46, %46, %50, %39, %40, %40, %41) : (!llvm.ptr, !llvm.ptr, i64, i64, i64, i64, i64, !llvm.ptr, !llvm.ptr, i64, i64, i64, i64, i64) -> !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
    %69 = llvm.mlir.constant(1 : index) : i64
    %70 = llvm.alloca %69 x !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> : (i64) -> !llvm.ptr
    llvm.store %68, %70 : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>, !llvm.ptr
    %71 = llvm.mlir.constant(2 : index) : i64
    %72 = llvm.mlir.undef : !llvm.struct<(i64, ptr)>
    %73 = llvm.insertvalue %71, %72[0] : !llvm.struct<(i64, ptr)> 
    %74 = llvm.insertvalue %70, %73[1] : !llvm.struct<(i64, ptr)> 
    llvm.call @printMemrefF64(%71, %70) : (i64, !llvm.ptr) -> ()
    llvm.return %0 : i32
  }
}

