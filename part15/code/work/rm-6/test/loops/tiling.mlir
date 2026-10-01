// Chapter 7: --affine-loop-tile="tile-size=2" turns the fused 2-deep nest into 4 loops (tile loops, then point loops).
// RUN: %mg-opt %s --affine-loop-tile="tile-size=2" | %FileCheck %s
// CHECK: affine.for %[[I:.*]] = 0 to 2 {
// CHECK-NEXT: affine.for %[[J:.*]] = 0 to 2 {
// CHECK-NEXT: affine.for %[[PI:.*]] = #map(%[[I]]) to #map1(%[[I]]) {
// CHECK-NEXT: affine.for %[[PJ:.*]] = #map(%[[J]]) to #map1(%[[J]]) {
// CHECK: affine.load %arg0[%[[PJ]], %[[PI]]]
// CHECK: affine.store %{{.*}}, %{{.*}}[%[[PI]], %[[PJ]]]
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

