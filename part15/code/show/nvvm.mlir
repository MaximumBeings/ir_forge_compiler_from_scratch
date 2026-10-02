module attributes {gpu.container_module} {
  func.func @add_tensors(%arg0: memref<2x2xf64>, %arg1: memref<2x2xf64>) -> memref<2x2xf64> {
    %alloc = memref.alloc() : memref<2x2xf64>
    %c0 = arith.constant 0 : index
    %c2 = arith.constant 2 : index
    %c1 = arith.constant 1 : index
    %c1_0 = arith.constant 1 : index
    %c2_1 = arith.constant 2 : index
    %c2_2 = arith.constant 2 : index
    %c0_3 = arith.constant 0 : index
    %c1_4 = arith.constant 1 : index
    %c2_5 = arith.constant 2 : index
    gpu.launch_func  @add_tensors_kernel::@add_tensors_kernel blocks in (%c2_1, %c1_0, %c1_0) threads in (%c2_5, %c1_0, %c1_0)  args(%c1 : index, %c0 : index, %arg0 : memref<2x2xf64>, %arg1 : memref<2x2xf64>, %alloc : memref<2x2xf64>)
    return %alloc : memref<2x2xf64>
  }
  gpu.module @add_tensors_kernel [#nvvm.target<chip = "sm_70">]  {
    llvm.func @add_tensors_kernel(%arg0: i64, %arg1: i64, %arg2: !llvm.ptr, %arg3: !llvm.ptr, %arg4: i64, %arg5: i64, %arg6: i64, %arg7: i64, %arg8: i64, %arg9: !llvm.ptr, %arg10: !llvm.ptr, %arg11: i64, %arg12: i64, %arg13: i64, %arg14: i64, %arg15: i64, %arg16: !llvm.ptr, %arg17: !llvm.ptr, %arg18: i64, %arg19: i64, %arg20: i64, %arg21: i64, %arg22: i64) attributes {gpu.kernel, nvvm.kernel} {
      %0 = llvm.mlir.undef : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
      %1 = llvm.insertvalue %arg2, %0[0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
      %2 = llvm.insertvalue %arg3, %1[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
      %3 = llvm.insertvalue %arg4, %2[2] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
      %4 = llvm.insertvalue %arg5, %3[3, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
      %5 = llvm.insertvalue %arg7, %4[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
      %6 = llvm.insertvalue %arg6, %5[3, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
      %7 = llvm.insertvalue %arg8, %6[4, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
      %8 = llvm.mlir.undef : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
      %9 = llvm.insertvalue %arg9, %8[0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
      %10 = llvm.insertvalue %arg10, %9[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
      %11 = llvm.insertvalue %arg11, %10[2] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
      %12 = llvm.insertvalue %arg12, %11[3, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
      %13 = llvm.insertvalue %arg14, %12[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
      %14 = llvm.insertvalue %arg13, %13[3, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
      %15 = llvm.insertvalue %arg15, %14[4, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
      %16 = llvm.mlir.undef : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)>
      %17 = llvm.insertvalue %arg16, %16[0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
      %18 = llvm.insertvalue %arg17, %17[1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
      %19 = llvm.insertvalue %arg18, %18[2] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
      %20 = llvm.insertvalue %arg19, %19[3, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
      %21 = llvm.insertvalue %arg21, %20[4, 0] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
      %22 = llvm.insertvalue %arg20, %21[3, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
      %23 = llvm.insertvalue %arg22, %22[4, 1] : !llvm.struct<(ptr, ptr, i64, array<2 x i64>, array<2 x i64>)> 
      %24 = nvvm.read.ptx.sreg.ctaid.x : i32
      %25 = llvm.sext %24 : i32 to i64
      %26 = nvvm.read.ptx.sreg.tid.x : i32
      %27 = llvm.sext %26 : i32 to i64
      llvm.br ^bb1
    ^bb1:  // pred: ^bb0
      %28 = llvm.mul %25, %arg0  : i64
      %29 = llvm.add %28, %arg1  : i64
      %30 = llvm.mlir.constant(2 : index) : i64
      %31 = llvm.mul %29, %30  : i64
      %32 = llvm.add %31, %27  : i64
      %33 = llvm.getelementptr %arg3[%32] : (!llvm.ptr, i64) -> !llvm.ptr, f64
      %34 = llvm.load %33 : !llvm.ptr -> f64
      %35 = llvm.mlir.constant(2 : index) : i64
      %36 = llvm.mul %29, %35  : i64
      %37 = llvm.add %36, %27  : i64
      %38 = llvm.getelementptr %arg10[%37] : (!llvm.ptr, i64) -> !llvm.ptr, f64
      %39 = llvm.load %38 : !llvm.ptr -> f64
      %40 = llvm.fadd %34, %39  : f64
      %41 = llvm.mlir.constant(2 : index) : i64
      %42 = llvm.mul %29, %41  : i64
      %43 = llvm.add %42, %27  : i64
      %44 = llvm.getelementptr %arg17[%43] : (!llvm.ptr, i64) -> !llvm.ptr, f64
      llvm.store %40, %44 : f64, !llvm.ptr
      llvm.return
    }
  }
}

