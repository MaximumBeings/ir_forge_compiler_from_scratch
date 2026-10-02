module {
  func.func private @printMemrefF64(memref<*xf64>) attributes {llvm.emit_c_interface}
  func.func @compute(%arg0: memref<2x2xf64>, %arg1: memref<2x2xf64>) {
    %alloc = memref.alloc() : memref<1x1xf64>
    %alloc_0 = memref.alloc() : memref<2x2xf64>
    %0 = affine.load %arg0[0, 0] : memref<2x2xf64>
    %1 = affine.load %arg1[0, 0] : memref<2x2xf64>
    %2 = arith.addf %0, %1 : f64
    affine.store %2, %alloc[0, 0] : memref<1x1xf64>
    %3 = affine.load %alloc[0, 0] : memref<1x1xf64>
    affine.store %3, %alloc_0[0, 0] : memref<2x2xf64>
    %4 = affine.load %arg0[1, 0] : memref<2x2xf64>
    %5 = affine.load %arg1[1, 0] : memref<2x2xf64>
    %6 = arith.addf %4, %5 : f64
    affine.store %6, %alloc[0, 0] : memref<1x1xf64>
    %7 = affine.load %alloc[0, 0] : memref<1x1xf64>
    affine.store %7, %alloc_0[0, 1] : memref<2x2xf64>
    %8 = affine.load %arg0[0, 1] : memref<2x2xf64>
    %9 = affine.load %arg1[0, 1] : memref<2x2xf64>
    %10 = arith.addf %8, %9 : f64
    affine.store %10, %alloc[0, 0] : memref<1x1xf64>
    %11 = affine.load %alloc[0, 0] : memref<1x1xf64>
    affine.store %11, %alloc_0[1, 0] : memref<2x2xf64>
    %12 = affine.load %arg0[1, 1] : memref<2x2xf64>
    %13 = affine.load %arg1[1, 1] : memref<2x2xf64>
    %14 = arith.addf %12, %13 : f64
    affine.store %14, %alloc[0, 0] : memref<1x1xf64>
    %15 = affine.load %alloc[0, 0] : memref<1x1xf64>
    affine.store %15, %alloc_0[1, 1] : memref<2x2xf64>
    %cast = memref.cast %alloc_0 : memref<2x2xf64> to memref<*xf64>
    call @printMemrefF64(%cast) : (memref<*xf64>) -> ()
    return
  }
}

