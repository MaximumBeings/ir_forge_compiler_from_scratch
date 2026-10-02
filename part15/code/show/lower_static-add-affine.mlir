module {
  func.func @add_tensors(%arg0: memref<2x2xf64>, %arg1: memref<2x2xf64>) -> memref<2x2xf64> {
    %alloc = memref.alloc() : memref<2x2xf64>
    affine.for %arg2 = 0 to 2 {
      affine.for %arg3 = 0 to 2 {
        %0 = affine.load %arg0[%arg2, %arg3] : memref<2x2xf64>
        %1 = affine.load %arg1[%arg2, %arg3] : memref<2x2xf64>
        %2 = arith.addf %0, %1 : f64
        affine.store %2, %alloc[%arg2, %arg3] : memref<2x2xf64>
      }
    }
    return %alloc : memref<2x2xf64>
  }
}

