// Chapter 7: --affine-loop-fusion merges the add nest and the transpose nest (4 loops -> 2).
// RUN: %mg-opt %s --affine-loop-fusion | %FileCheck %s
// CHECK: func.func @compute
// CHECK: affine.for
// CHECK-NEXT: affine.for
// CHECK-NOT: affine.for
module {
  func.func private @printMemrefF64(memref<*xf64>) attributes {llvm.emit_c_interface}
  func.func @compute(%arg0: memref<2x2xf64>, %arg1: memref<2x2xf64>) {
    %alloc = memref.alloc() : memref<2x2xf64>
    affine.for %arg2 = 0 to 2 {
      affine.for %arg3 = 0 to 2 {
        %0 = affine.load %arg0[%arg2, %arg3] : memref<2x2xf64>
        %1 = affine.load %arg1[%arg2, %arg3] : memref<2x2xf64>
        %2 = arith.addf %0, %1 : f64
        affine.store %2, %alloc[%arg2, %arg3] : memref<2x2xf64>
      }
    }
    %alloc_0 = memref.alloc() : memref<2x2xf64>
    affine.for %arg2 = 0 to 2 {
      affine.for %arg3 = 0 to 2 {
        %0 = affine.load %alloc[%arg3, %arg2] : memref<2x2xf64>
        affine.store %0, %alloc_0[%arg2, %arg3] : memref<2x2xf64>
      }
    }
    %cast = memref.cast %alloc_0 : memref<2x2xf64> to memref<*xf64>
    call @printMemrefF64(%cast) : (memref<*xf64>) -> ()
    return
  }
}

