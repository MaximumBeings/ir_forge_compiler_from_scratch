#map = affine_map<(d0) -> (d0)>
module {
  func.func @mm(%arg0: memref<?x?xf64>, %arg1: memref<?x?xf64>) -> memref<?x?xf64> {
    %c1 = arith.constant 1 : index
    %dim = memref.dim %arg0, %c1 : memref<?x?xf64>
    %c0 = arith.constant 0 : index
    %dim_0 = memref.dim %arg1, %c0 : memref<?x?xf64>
    %0 = arith.cmpi eq, %dim, %dim_0 : index
    cf.assert %0, "mg.matmul: inner dimensions differ at runtime"
    %c0_1 = arith.constant 0 : index
    %dim_2 = memref.dim %arg0, %c0_1 : memref<?x?xf64>
    %c1_3 = arith.constant 1 : index
    %dim_4 = memref.dim %arg1, %c1_3 : memref<?x?xf64>
    %alloc = memref.alloc(%dim_2, %dim_4) : memref<?x?xf64>
    %cst = arith.constant 0.000000e+00 : f64
    %c0_5 = arith.constant 0 : index
    affine.for %arg2 = #map(%c0_5) to #map(%dim_2) {
      affine.for %arg3 = #map(%c0_5) to #map(%dim_4) {
        affine.store %cst, %alloc[%arg2, %arg3] : memref<?x?xf64>
      }
    }
    %c0_6 = arith.constant 0 : index
    %dim_7 = memref.dim %arg0, %c0_6 : memref<?x?xf64>
    %c1_8 = arith.constant 1 : index
    %dim_9 = memref.dim %arg1, %c1_8 : memref<?x?xf64>
    %c1_10 = arith.constant 1 : index
    %dim_11 = memref.dim %arg0, %c1_10 : memref<?x?xf64>
    %c0_12 = arith.constant 0 : index
    affine.for %arg2 = #map(%c0_12) to #map(%dim_7) {
      affine.for %arg3 = #map(%c0_12) to #map(%dim_9) {
        affine.for %arg4 = #map(%c0_12) to #map(%dim_11) {
          %1 = affine.load %alloc[%arg2, %arg3] : memref<?x?xf64>
          %2 = affine.load %arg0[%arg2, %arg4] : memref<?x?xf64>
          %3 = affine.load %arg1[%arg4, %arg3] : memref<?x?xf64>
          %4 = arith.mulf %2, %3 : f64
          %5 = arith.addf %1, %4 : f64
          affine.store %5, %alloc[%arg2, %arg3] : memref<?x?xf64>
        }
      }
    }
    return %alloc : memref<?x?xf64>
  }
}

