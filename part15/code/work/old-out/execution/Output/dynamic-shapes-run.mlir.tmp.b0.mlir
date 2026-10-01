#map = affine_map<(d0) -> (d0)>
module {
  func.func @add_dyn(%arg0: memref<?x?xf64, strided<[?, ?], offset: ?>>, %arg1: memref<?x?xf64, strided<[?, ?], offset: ?>>) -> memref<?x?xf64> {
    %c0 = arith.constant 0 : index
    %dim = memref.dim %arg0, %c0 : memref<?x?xf64, strided<[?, ?], offset: ?>>
    %c1 = arith.constant 1 : index
    %dim_0 = memref.dim %arg0, %c1 : memref<?x?xf64, strided<[?, ?], offset: ?>>
    %alloc = memref.alloc(%dim, %dim_0) : memref<?x?xf64>
    %c0_1 = arith.constant 0 : index
    affine.for %arg2 = #map(%c0_1) to #map(%dim) {
      affine.for %arg3 = #map(%c0_1) to #map(%dim_0) {
        %0 = affine.load %arg0[%arg2, %arg3] : memref<?x?xf64, strided<[?, ?], offset: ?>>
        %1 = affine.load %arg1[%arg2, %arg3] : memref<?x?xf64, strided<[?, ?], offset: ?>>
        %2 = arith.addf %0, %1 : f64
        affine.store %2, %alloc[%arg2, %arg3] : memref<?x?xf64>
      }
    }
    %cast = memref.cast %alloc : memref<?x?xf64> to memref<?x?xf64, strided<[?, ?], offset: ?>>
    return %alloc : memref<?x?xf64>
  }
  func.func @t_dyn(%arg0: memref<?x?xf64, strided<[?, ?], offset: ?>>) -> memref<?x?xf64> {
    %c1 = arith.constant 1 : index
    %dim = memref.dim %arg0, %c1 : memref<?x?xf64, strided<[?, ?], offset: ?>>
    %c0 = arith.constant 0 : index
    %dim_0 = memref.dim %arg0, %c0 : memref<?x?xf64, strided<[?, ?], offset: ?>>
    %alloc = memref.alloc(%dim, %dim_0) : memref<?x?xf64>
    %c0_1 = arith.constant 0 : index
    affine.for %arg1 = #map(%c0_1) to #map(%dim) {
      affine.for %arg2 = #map(%c0_1) to #map(%dim_0) {
        %0 = affine.load %arg0[%arg2, %arg1] : memref<?x?xf64, strided<[?, ?], offset: ?>>
        affine.store %0, %alloc[%arg1, %arg2] : memref<?x?xf64>
      }
    }
    %cast = memref.cast %alloc : memref<?x?xf64> to memref<?x?xf64, strided<[?, ?], offset: ?>>
    return %alloc : memref<?x?xf64>
  }
}

