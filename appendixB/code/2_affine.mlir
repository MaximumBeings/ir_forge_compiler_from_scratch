module {
  func.func private @printMemrefF64(memref<*xf64>) attributes {llvm.emit_c_interface}
  func.func @scale_add(%arg0: memref<1x3xf64>, %arg1: memref<1x3xf64>) -> memref<1x3xf64> {
    %alloc = memref.alloc() : memref<1x3xf64>
    %cst = arith.constant 2.000000e+00 : f64
    affine.for %arg2 = 0 to 1 {
      affine.for %arg3 = 0 to 3 {
        %0 = affine.load %arg0[%arg2, %arg3] : memref<1x3xf64>
        %1 = arith.mulf %0, %cst : f64
        affine.store %1, %alloc[%arg2, %arg3] : memref<1x3xf64>
      }
    }
    %alloc_0 = memref.alloc() : memref<1x3xf64>
    affine.for %arg2 = 0 to 1 {
      affine.for %arg3 = 0 to 3 {
        %0 = affine.load %alloc[%arg2, %arg3] : memref<1x3xf64>
        %1 = affine.load %arg1[%arg2, %arg3] : memref<1x3xf64>
        %2 = arith.addf %0, %1 : f64
        affine.store %2, %alloc_0[%arg2, %arg3] : memref<1x3xf64>
      }
    }
    return %alloc_0 : memref<1x3xf64>
  }
  func.func @main() -> i32 {
    %alloc = memref.alloc() : memref<1x3xf64>
    %cst = arith.constant 1.000000e+00 : f64
    %c0 = arith.constant 0 : index
    %c0_0 = arith.constant 0 : index
    affine.store %cst, %alloc[%c0, %c0_0] : memref<1x3xf64>
    %cst_1 = arith.constant 2.000000e+00 : f64
    %c0_2 = arith.constant 0 : index
    %c1 = arith.constant 1 : index
    affine.store %cst_1, %alloc[%c0_2, %c1] : memref<1x3xf64>
    %cst_3 = arith.constant 3.000000e+00 : f64
    %c0_4 = arith.constant 0 : index
    %c2 = arith.constant 2 : index
    affine.store %cst_3, %alloc[%c0_4, %c2] : memref<1x3xf64>
    %alloc_5 = memref.alloc() : memref<1x3xf64>
    %cst_6 = arith.constant 1.000000e+01 : f64
    %c0_7 = arith.constant 0 : index
    %c0_8 = arith.constant 0 : index
    affine.store %cst_6, %alloc_5[%c0_7, %c0_8] : memref<1x3xf64>
    %cst_9 = arith.constant 2.000000e+01 : f64
    %c0_10 = arith.constant 0 : index
    %c1_11 = arith.constant 1 : index
    affine.store %cst_9, %alloc_5[%c0_10, %c1_11] : memref<1x3xf64>
    %cst_12 = arith.constant 3.000000e+01 : f64
    %c0_13 = arith.constant 0 : index
    %c2_14 = arith.constant 2 : index
    affine.store %cst_12, %alloc_5[%c0_13, %c2_14] : memref<1x3xf64>
    %0 = call @scale_add(%alloc, %alloc_5) : (memref<1x3xf64>, memref<1x3xf64>) -> memref<1x3xf64>
    %cast = memref.cast %0 : memref<1x3xf64> to memref<*xf64>
    call @printMemrefF64(%cast) : (memref<*xf64>) -> ()
    %c0_i32 = arith.constant 0 : i32
    return %c0_i32 : i32
  }
}

