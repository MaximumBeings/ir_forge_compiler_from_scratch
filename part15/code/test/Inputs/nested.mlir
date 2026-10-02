func.func @nanloop(%a: memref<?xf64>, %n: index) {
  affine.for %i = 0 to %n {
    %v = affine.load %a[%i] : memref<?xf64>
    %ok = arith.cmpf oeq, %v, %v : f64
    cf.assert %ok, "value is NaN"
  }
  return
}
