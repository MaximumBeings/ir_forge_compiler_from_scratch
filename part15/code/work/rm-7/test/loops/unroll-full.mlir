// Chapter 7: fully unrolling both loops, then canonicalizing, leaves NO loops, four add-and-store groups
// with constant indices, and no leftover affine.apply index arithmetic.
// RUN: %mg-opt %s --affine-loop-unroll="unroll-full" --canonicalize | %FileCheck %s
// CHECK-NOT: affine.for
// CHECK-NOT: affine.apply
// CHECK: affine.load %arg0[0, 0]
// CHECK: affine.store %{{.*}}, %{{.*}}[0, 0] : memref<2x2xf64>
// CHECK: affine.load %arg0[1, 0]
// CHECK: affine.store %{{.*}}, %{{.*}}[0, 1] : memref<2x2xf64>
// CHECK: affine.load %arg0[0, 1]
// CHECK: affine.store %{{.*}}, %{{.*}}[1, 0] : memref<2x2xf64>
// CHECK: affine.load %arg0[1, 1]
// CHECK: affine.store %{{.*}}, %{{.*}}[1, 1] : memref<2x2xf64>
// CHECK-NOT: affine.for
module {
  func.func private @printMemrefF64(memref<*xf64>) attributes {llvm.emit_c_interface}
  func.func @compute(%arg0: memref<2x2xf64>, %arg1: memref<2x2xf64>) {
    %alloc = memref.alloc() : memref<1x1xf64>
    %alloc_0 = memref.alloc() : memref<2x2xf64>
    affine.for %arg2 = 0 to 2 {
      affine.for %arg3 = 0 to 2 {
        %0 = affine.load %arg0[%arg3, %arg2] : memref<2x2xf64>
        %1 = affine.load %arg1[%arg3, %arg2] : memref<2x2xf64>
        %2 = arith.addf %0, %1 : f64
        affine.store %2, %alloc[0, 0] : memref<1x1xf64>
        %3 = affine.load %alloc[0, 0] : memref<1x1xf64>
        affine.store %3, %alloc_0[%arg2, %arg3] : memref<2x2xf64>
      }
    }
    %cast = memref.cast %alloc_0 : memref<2x2xf64> to memref<*xf64>
    call @printMemrefF64(%cast) : (memref<*xf64>) -> ()
    return
  }
}

