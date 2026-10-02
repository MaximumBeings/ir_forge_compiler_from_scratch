module {
  func.func @f(%arg0: memref<2x3xf64>) -> memref<2x1xf64> {
    %alloc = memref.alloc() : memref<2x1xf64>
    %cst = arith.constant 0.000000e+00 : f64
    affine.for %arg1 = 0 to 2 {
      affine.for %arg2 = 0 to 1 {
        affine.store %cst, %alloc[%arg1, %arg2] : memref<2x1xf64>
      }
    }
    affine.for %arg1 = 0 to 2 {
      affine.for %arg2 = 0 to 3 {
        %c0 = arith.constant 0 : index
        %0 = affine.load %alloc[%arg1, %c0] : memref<2x1xf64>
        %1 = affine.load %arg0[%arg1, %arg2] : memref<2x3xf64>
        %2 = arith.addf %0, %1 : f64
        affine.store %2, %alloc[%arg1, %c0] : memref<2x1xf64>
      }
    }
    return %alloc : memref<2x1xf64>
  }
}

