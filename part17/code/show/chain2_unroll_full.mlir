#map = affine_map<(d0) -> (d0)>
#map1 = affine_map<(d0) -> (d0 + 1)>
module {
  func.func @chain2(%arg0: memref<?x2xf64>, %arg1: memref<?x2xf64>) -> memref<2x?xf64> {
    %c0 = arith.constant 0 : index
    %c0_0 = arith.constant 0 : index
    %dim = memref.dim %arg0, %c0_0 : memref<?x2xf64>
    %c0_1 = arith.constant 0 : index
    %dim_2 = memref.dim %arg1, %c0_1 : memref<?x2xf64>
    %0 = arith.cmpi eq, %dim, %dim_2 : index
    cf.assert %0, "mg.add: operand shapes differ at runtime in dimension 0"
    %c0_3 = arith.constant 0 : index
    %dim_4 = memref.dim %arg0, %c0_3 : memref<?x2xf64>
    %alloc = memref.alloc(%dim_4) : memref<?x2xf64>
    %c0_5 = arith.constant 0 : index
    %c2 = arith.constant 2 : index
    affine.for %arg2 = #map(%c0_5) to #map(%dim_4) {
      %1 = affine.load %arg0[%arg2, %c0] : memref<?x2xf64>
      %2 = affine.load %arg1[%arg2, %c0] : memref<?x2xf64>
      %3 = arith.addf %1, %2 : f64
      affine.store %3, %alloc[%arg2, %c0] : memref<?x2xf64>
      %4 = affine.apply #map1(%c0)
      %5 = affine.load %arg0[%arg2, %4] : memref<?x2xf64>
      %6 = affine.load %arg1[%arg2, %4] : memref<?x2xf64>
      %7 = arith.addf %5, %6 : f64
      affine.store %7, %alloc[%arg2, %4] : memref<?x2xf64>
    }
    %c0_6 = arith.constant 0 : index
    %dim_7 = memref.dim %alloc, %c0_6 : memref<?x2xf64>
    %alloc_8 = memref.alloc(%dim_7) : memref<2x?xf64>
    %c0_9 = arith.constant 0 : index
    %c2_10 = arith.constant 2 : index
    affine.for %arg2 = 0 to 2 {
      affine.for %arg3 = #map(%c0_9) to #map(%dim_7) {
        %1 = affine.load %alloc[%arg3, %arg2] : memref<?x2xf64>
        affine.store %1, %alloc_8[%arg2, %arg3] : memref<2x?xf64>
      }
    }
    return %alloc_8 : memref<2x?xf64>
  }
}

