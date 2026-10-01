#map = affine_map<(d0) -> (d0)>
module {
  func.func @add_dyn(%arg0: memref<?x?xf64, strided<[?, ?], offset: ?>>, %arg1: memref<?x?xf64, strided<[?, ?], offset: ?>>) -> memref<?x?xf64> {
    %c0 = arith.constant 0 : index
    %dim = memref.dim %arg0, %c0 : memref<?x?xf64, strided<[?, ?], offset: ?>>
    %c0_0 = arith.constant 0 : index
    %dim_1 = memref.dim %arg1, %c0_0 : memref<?x?xf64, strided<[?, ?], offset: ?>>
    %0 = arith.cmpi eq, %dim, %dim_1 : index
    cf.assert %0, "mg.add: operand shapes differ at runtime in dimension 0"
    %c0_2 = arith.constant 0 : index
    %dim_3 = memref.dim %arg0, %c0_2 : memref<?x?xf64, strided<[?, ?], offset: ?>>
    %c1 = arith.constant 1 : index
    %dim_4 = memref.dim %arg0, %c1 : memref<?x?xf64, strided<[?, ?], offset: ?>>
    %alloc = memref.alloc(%dim_3, %dim_4) : memref<?x?xf64>
    %c0_5 = arith.constant 0 : index
    affine.for %arg2 = #map(%c0_5) to #map(%dim_3) {
      affine.for %arg3 = #map(%c0_5) to #map(%dim_4) {
        %1 = affine.load %arg0[%arg2, %arg3] : memref<?x?xf64, strided<[?, ?], offset: ?>>
        %2 = affine.load %arg1[%arg2, %arg3] : memref<?x?xf64, strided<[?, ?], offset: ?>>
        %3 = arith.addf %1, %2 : f64
        affine.store %3, %alloc[%arg2, %arg3] : memref<?x?xf64>
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

