#map = affine_map<(d0) -> (d0)>
module {
  func.func @t(%arg0: memref<?x?xf64>) -> memref<?x?xf64> {
    %c1 = arith.constant 1 : index
    %dim = memref.dim %arg0, %c1 : memref<?x?xf64>
    %c0 = arith.constant 0 : index
    %dim_0 = memref.dim %arg0, %c0 : memref<?x?xf64>
    %alloc = memref.alloc(%dim, %dim_0) : memref<?x?xf64>
    %c0_1 = arith.constant 0 : index
    affine.for %arg1 = #map(%c0_1) to #map(%dim) {
      affine.for %arg2 = #map(%c0_1) to #map(%dim_0) {
        %0 = affine.load %arg0[%arg2, %arg1] : memref<?x?xf64>
        affine.store %0, %alloc[%arg1, %arg2] : memref<?x?xf64>
      }
    }
    return %alloc : memref<?x?xf64>
  }
}

