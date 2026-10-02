#map = affine_map<(d0) -> (d0)>
module {
  func.func @chain2(%arg0: memref<?x2xf64>, %arg1: memref<?x2xf64>) -> memref<2x?xf64> {
    %c0 = arith.constant 0 : index
    %dim = memref.dim %arg0, %c0 : memref<?x2xf64>
    %c0_0 = arith.constant 0 : index
    %dim_1 = memref.dim %arg1, %c0_0 : memref<?x2xf64>
    %0 = arith.cmpi eq, %dim, %dim_1 : index
    cf.assert %0, "mg.add: operand shapes differ at runtime in dimension 0"
    %c0_2 = arith.constant 0 : index
    %dim_3 = memref.dim %arg0, %c0_2 : memref<?x2xf64>
    %alloc = memref.alloc(%dim_3) : memref<?x2xf64>
    %c0_4 = arith.constant 0 : index
    %c2 = arith.constant 2 : index
    affine.for %arg2 = #map(%c0_4) to #map(%dim_3) {
      affine.for %arg3 = 0 to 2 {
        %1 = affine.load %arg0[%arg2, %arg3] : memref<?x2xf64>
        %2 = affine.load %arg1[%arg2, %arg3] : memref<?x2xf64>
        %3 = arith.addf %1, %2 : f64
        affine.store %3, %alloc[%arg2, %arg3] : memref<?x2xf64>
      }
    }
    %c0_5 = arith.constant 0 : index
    %dim_6 = memref.dim %alloc, %c0_5 : memref<?x2xf64>
    %alloc_7 = memref.alloc(%dim_6) : memref<2x?xf64>
    %c0_8 = arith.constant 0 : index
    %c2_9 = arith.constant 2 : index
    affine.for %arg2 = 0 to 2 {
      affine.for %arg3 = #map(%c0_8) to #map(%dim_6) {
        %1 = affine.load %alloc[%arg3, %arg2] : memref<?x2xf64>
        affine.store %1, %alloc_7[%arg2, %arg3] : memref<2x?xf64>
      }
    }
    return %alloc_7 : memref<2x?xf64>
  }
}

