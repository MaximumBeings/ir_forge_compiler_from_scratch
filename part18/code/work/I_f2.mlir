#map = affine_map<(d0) -> (d0)>
#map1 = affine_map<(d0) -> (d0 + 2)>
module {
  func.func @chain(%arg0: memref<4x6xf64>, %arg1: memref<4x6xf64>) -> memref<6x4xf64> {
    %alloc = memref.alloc() : memref<4x6xf64>
    affine.for %arg2 = 0 to 4 step 2 {
      affine.for %arg3 = 0 to 6 step 2 {
        affine.for %arg4 = #map(%arg2) to #map1(%arg2) {
          affine.for %arg5 = #map(%arg3) to #map1(%arg3) {
            %0 = affine.load %arg0[%arg4, %arg5] : memref<4x6xf64>
            %1 = affine.load %arg1[%arg4, %arg5] : memref<4x6xf64>
            %2 = arith.addf %0, %1 : f64
            affine.store %2, %alloc[%arg4, %arg5] : memref<4x6xf64>
          }
        }
      }
    }
    %alloc_0 = memref.alloc() : memref<6x4xf64>
    affine.for %arg2 = 0 to 6 step 2 {
      affine.for %arg3 = 0 to 4 step 2 {
        affine.for %arg4 = #map(%arg2) to #map1(%arg2) {
          affine.for %arg5 = #map(%arg3) to #map1(%arg3) {
            %0 = affine.load %alloc[%arg5, %arg4] : memref<4x6xf64>
            affine.store %0, %alloc_0[%arg4, %arg5] : memref<6x4xf64>
          }
        }
      }
    }
    return %alloc_0 : memref<6x4xf64>
  }
}

