module {
  func.func @chain(%arg0: memref<4x6xf64>, %arg1: memref<4x6xf64>) -> memref<6x4xf64> {
    %alloc = memref.alloc() : memref<1x1xf64>
    %alloc_0 = memref.alloc() : memref<6x4xf64>
    affine.for %arg2 = 0 to 6 {
      affine.for %arg3 = 0 to 4 {
        %0 = affine.load %arg0[%arg3, %arg2] : memref<4x6xf64>
        %1 = affine.load %arg1[%arg3, %arg2] : memref<4x6xf64>
        %2 = arith.addf %0, %1 : f64
        affine.store %2, %alloc[0, 0] : memref<1x1xf64>
        %3 = affine.load %alloc[0, 0] : memref<1x1xf64>
        affine.store %3, %alloc_0[%arg2, %arg3] : memref<6x4xf64>
      }
    }
    return %alloc_0 : memref<6x4xf64>
  }
}

