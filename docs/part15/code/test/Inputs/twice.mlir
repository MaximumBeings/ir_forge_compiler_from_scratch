func.func @f(%a: memref<?xf64>, %n: index, %ok: i1) {
  cf.assert %ok, "top-level check"
  affine.for %i = 0 to %n {
    %v = affine.load %a[%i] : memref<?xf64>
    %fine = arith.cmpf oeq, %v, %v : f64
    cf.assert %fine, "value is NaN"
  }
  return
}
