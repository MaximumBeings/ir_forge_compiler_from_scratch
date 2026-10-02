func.func @C(%a: memref<4x6xf64>, %b: memref<4x6xf64>) -> memref<6x4xf64> {
  %s = memref.alloc() : memref<4x6xf64>
  %out = memref.alloc() : memref<6x4xf64>
  affine.for %i = 0 to 4 {
    affine.for %j = 0 to 6 {
      %x = affine.load %a[%i, %j] : memref<4x6xf64>
      %y = affine.load %b[%i, %j] : memref<4x6xf64>
      %z = arith.addf %x, %y : f64
      affine.store %z, %s[%i, %j] : memref<4x6xf64>
    }
  }
  affine.for %i = 0 to 6 {
    affine.for %j = 0 to 4 {
      %t = affine.load %s[%j, %i] : memref<4x6xf64>
      affine.store %t, %out[%i, %j] : memref<6x4xf64>
    }
  }
  return %out : memref<6x4xf64>
}
