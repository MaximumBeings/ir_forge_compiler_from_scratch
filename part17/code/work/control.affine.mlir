#map = affine_map<(d0) -> (d0)>
module {
  func.func @chain(%arg0: memref<?x?xf64>, %arg1: memref<?x?xf64>) -> memref<?x?xf64> {
    %c0 = arith.constant 0 : index
    %dim = memref.dim %arg0, %c0 : memref<?x?xf64>
    %c0_0 = arith.constant 0 : index
    %dim_1 = memref.dim %arg1, %c0_0 : memref<?x?xf64>
    %0 = arith.cmpi eq, %dim, %dim_1 : index
    cf.assert %0, "mg.add: operand shapes differ at runtime in dimension 0"
    %c1 = arith.constant 1 : index
    %dim_2 = memref.dim %arg0, %c1 : memref<?x?xf64>
    %c1_3 = arith.constant 1 : index
    %dim_4 = memref.dim %arg1, %c1_3 : memref<?x?xf64>
    %1 = arith.cmpi eq, %dim_2, %dim_4 : index
    cf.assert %1, "mg.add: operand shapes differ at runtime in dimension 1"
    %c0_5 = arith.constant 0 : index
    %dim_6 = memref.dim %arg0, %c0_5 : memref<?x?xf64>
    %c1_7 = arith.constant 1 : index
    %dim_8 = memref.dim %arg0, %c1_7 : memref<?x?xf64>
    %alloc = memref.alloc(%dim_6, %dim_8) : memref<?x?xf64>
    %c0_9 = arith.constant 0 : index
    affine.for %arg2 = #map(%c0_9) to #map(%dim_6) {
      affine.for %arg3 = #map(%c0_9) to #map(%dim_8) {
        %2 = affine.load %arg0[%arg2, %arg3] : memref<?x?xf64>
        %3 = affine.load %arg1[%arg2, %arg3] : memref<?x?xf64>
        %4 = arith.subf %2, %3 : f64
        affine.store %4, %alloc[%arg2, %arg3] : memref<?x?xf64>
      }
    }
    %c1_10 = arith.constant 1 : index
    %dim_11 = memref.dim %alloc, %c1_10 : memref<?x?xf64>
    %c0_12 = arith.constant 0 : index
    %dim_13 = memref.dim %alloc, %c0_12 : memref<?x?xf64>
    %alloc_14 = memref.alloc(%dim_11, %dim_13) : memref<?x?xf64>
    %c0_15 = arith.constant 0 : index
    affine.for %arg2 = #map(%c0_15) to #map(%dim_11) {
      affine.for %arg3 = #map(%c0_15) to #map(%dim_13) {
        %2 = affine.load %alloc[%arg3, %arg2] : memref<?x?xf64>
        affine.store %2, %alloc_14[%arg2, %arg3] : memref<?x?xf64>
      }
    }
    return %alloc_14 : memref<?x?xf64>
  }
}

