module {
  func.func @mm(%arg0: memref<2x3xf64>, %arg1: memref<3x4xf64>) -> memref<2x4xf64> {
    %alloc = memref.alloc() : memref<2x4xf64>
    %cst = arith.constant 0.000000e+00 : f64
    affine.for %arg2 = 0 to 2 {
      affine.for %arg3 = 0 to 4 {
        affine.store %cst, %alloc[%arg2, %arg3] : memref<2x4xf64>
      }
    }
    %c2 = arith.constant 2 : index
    %c4 = arith.constant 4 : index
    %c3 = arith.constant 3 : index
    %c0 = arith.constant 0 : index
    affine.for %arg2 = 0 to 2 {
      affine.for %arg3 = 0 to 4 {
        affine.for %arg4 = 0 to 3 {
          %0 = affine.load %alloc[%arg2, %arg3] : memref<2x4xf64>
          %1 = affine.load %arg0[%arg2, %arg4] : memref<2x3xf64>
          %2 = affine.load %arg1[%arg4, %arg3] : memref<3x4xf64>
          %3 = arith.mulf %1, %2 : f64
          %4 = arith.addf %0, %3 : f64
          affine.store %4, %alloc[%arg2, %arg3] : memref<2x4xf64>
        }
      }
    }
    return %alloc : memref<2x4xf64>
  }
}

