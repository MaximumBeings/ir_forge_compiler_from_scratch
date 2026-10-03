// Chapter 38: the pass itself, on hand-written affine IR (--mg-outline-loops=min-loops=1 lowers the threshold so that two nests are enough).
// RUN: %mg-opt %s --mg-outline-loops=min-loops=1 | %FileCheck %s
// RUN: %mg-opt %s --mg-outline-loops | %FileCheck %s --check-prefix=DEFAULT
module {
  func.func @two_same_one_different(%a: memref<4xf64>, %b: memref<4xf64>, %c: memref<6xf64>) {
    %two = arith.constant 2.0 : f64
    affine.for %i = 0 to 4 {
      %x = affine.load %a[%i] : memref<4xf64>
      %y = arith.mulf %x, %two : f64
      affine.store %y, %b[%i] : memref<4xf64>
    }
    affine.for %i = 0 to 4 {
      %x = affine.load %b[%i] : memref<4xf64>
      %y = arith.mulf %x, %two : f64
      affine.store %y, %a[%i] : memref<4xf64>
    }
    affine.for %i = 0 to 6 {
      %x = affine.load %c[%i] : memref<6xf64>
      affine.store %x, %c[%i] : memref<6xf64>
    }
    return
  }
  func.func @scalar_argument(%a: memref<4xf64>, %k: f64) {
    affine.for %i = 0 to 4 {
      %x = affine.load %a[%i] : memref<4xf64>
      %y = arith.addf %x, %k : f64
      affine.store %y, %a[%i] : memref<4xf64>
    }
    return
  }
  func.func @nested_loop_untouched(%a: memref<4x4xf64>) {
    affine.for %i = 0 to 4 {
      affine.for %j = 0 to 4 {
        %x = affine.load %a[%i, %j] : memref<4x4xf64>
        affine.store %x, %a[%i, %j] : memref<4x4xf64>
      }
    }
    return
  }
}
// The first two nests are the same loop over the same shape with the same constant: ONE function (taking the two memrefs), called twice; the third (6 elements) is another. The
// constant is cloned into the function, not passed. Original order is kept: call, call, call.
// CHECK-LABEL: func.func @two_same_one_different
// CHECK: call @mg_outlined_0(%arg0, %arg1)
// CHECK-NEXT: call @mg_outlined_0(%arg1, %arg0)
// CHECK-NEXT: call @mg_outlined_1(%arg2)
// A scalar defined outside the nest (here a function argument) becomes an argument of the outlined function.
// CHECK-LABEL: func.func @scalar_argument
// CHECK: call @mg_outlined_2(%arg0, %arg1)
// A function with a single top-level nest is also outlined at min-loops=1; the loops inside a nest are never separated: the outlined function holds the whole 2-deep nest.
// CHECK-LABEL: func.func @nested_loop_untouched
// CHECK: call @mg_outlined_3(%arg0)
// CHECK-LABEL: func.func private @mg_outlined_0(%arg0: memref<4xf64>, %arg1: memref<4xf64>)
// CHECK: arith.constant 2.000000e+00 : f64
// CHECK: affine.for
// CHECK-LABEL: func.func private @mg_outlined_2(%arg0: memref<4xf64>, %arg1: f64)
// CHECK-LABEL: func.func private @mg_outlined_3(%arg0: memref<4x4xf64>)
// CHECK: affine.for
// CHECK-NEXT: affine.for
// With the default threshold (32 nests per function) none of these small functions is touched.
// DEFAULT-NOT: mg_outlined
