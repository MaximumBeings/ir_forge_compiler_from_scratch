#map = affine_map<(d0) -> (d0)>
module {
  func.func @addadd(%arg0: memref<?x?xf64>, %arg1: memref<?x?xf64>, %arg2: memref<?x?xf64>) -> memref<?x?xf64> {
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
    affine.for %arg3 = #map(%c0_9) to #map(%dim_6) {
      affine.for %arg4 = #map(%c0_9) to #map(%dim_8) {
        %4 = affine.load %arg0[%arg3, %arg4] : memref<?x?xf64>
        %5 = affine.load %arg1[%arg3, %arg4] : memref<?x?xf64>
        %6 = arith.addf %4, %5 : f64
        affine.store %6, %alloc[%arg3, %arg4] : memref<?x?xf64>
      }
    }
    %c0_10 = arith.constant 0 : index
    %dim_11 = memref.dim %alloc, %c0_10 : memref<?x?xf64>
    %c0_12 = arith.constant 0 : index
    %dim_13 = memref.dim %arg2, %c0_12 : memref<?x?xf64>
    %2 = arith.cmpi eq, %dim_11, %dim_13 : index
    cf.assert %2, "mg.add: operand shapes differ at runtime in dimension 0"
    %c1_14 = arith.constant 1 : index
    %dim_15 = memref.dim %alloc, %c1_14 : memref<?x?xf64>
    %c1_16 = arith.constant 1 : index
    %dim_17 = memref.dim %arg2, %c1_16 : memref<?x?xf64>
    %3 = arith.cmpi eq, %dim_15, %dim_17 : index
    cf.assert %3, "mg.add: operand shapes differ at runtime in dimension 1"
    %c0_18 = arith.constant 0 : index
    %dim_19 = memref.dim %alloc, %c0_18 : memref<?x?xf64>
    %c1_20 = arith.constant 1 : index
    %dim_21 = memref.dim %alloc, %c1_20 : memref<?x?xf64>
    %alloc_22 = memref.alloc(%dim_19, %dim_21) : memref<?x?xf64>
    %c0_23 = arith.constant 0 : index
    affine.for %arg3 = #map(%c0_23) to #map(%dim_19) {
      affine.for %arg4 = #map(%c0_23) to #map(%dim_21) {
        %4 = affine.load %alloc[%arg3, %arg4] : memref<?x?xf64>
        %5 = affine.load %arg2[%arg3, %arg4] : memref<?x?xf64>
        %6 = arith.addf %4, %5 : f64
        affine.store %6, %alloc_22[%arg3, %arg4] : memref<?x?xf64>
      }
    }
    return %alloc_22 : memref<?x?xf64>
  }
}

