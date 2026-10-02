func.func @B(%a: memref<?x?xf64>, %b: memref<?x?xf64>, %n: index, %m: index) -> memref<?x?xf64> {
  %s = memref.alloc(%n, %m) : memref<?x?xf64>
  %out = memref.alloc(%m, %n) : memref<?x?xf64>
  affine.for %i = 0 to 4 {
    affine.for %j = 0 to 6 {
      %x = affine.load %a[%i, %j] : memref<?x?xf64>
      %y = affine.load %b[%i, %j] : memref<?x?xf64>
      %z = arith.addf %x, %y : f64
      affine.store %z, %s[%i, %j] : memref<?x?xf64>
    }
  }
  affine.for %i = 0 to 6 {
    affine.for %j = 0 to 4 {
      %t = affine.load %s[%j, %i] : memref<?x?xf64>
      affine.store %t, %out[%i, %j] : memref<?x?xf64>
    }
  }
  return %out : memref<?x?xf64>
}
