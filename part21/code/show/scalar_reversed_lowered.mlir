module {
  func.func @f(%arg0: memref<2x2xf64>) -> memref<2x2xf64> {
    %alloc = memref.alloc() : memref<2x2xf64>
    %cst = arith.constant 1.000000e+01 : f64
    affine.for %arg1 = 0 to 2 {
      affine.for %arg2 = 0 to 2 {
        %0 = affine.load %arg0[%arg1, %arg2] : memref<2x2xf64>
        %1 = arith.subf %cst, %0 : f64
        affine.store %1, %alloc[%arg1, %arg2] : memref<2x2xf64>
      }
    }
    return %alloc : memref<2x2xf64>
  }
}

