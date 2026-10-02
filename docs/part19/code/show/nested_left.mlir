module {
  func.func @nanloop(%arg0: memref<?xf64>, %arg1: index) {
    affine.for %arg2 = 0 to %arg1 {
      %0 = affine.load %arg0[%arg2] : memref<?xf64>
      %1 = arith.cmpf oeq, %0, %0 : f64
      cf.assert %1, "value is NaN"
    }
    return
  }
}

