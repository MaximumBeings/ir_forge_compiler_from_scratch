// Chapters 13/14: dynamic add -> memref.dim extents, a runtime check per dimension, dynamic alloc.
// RUN: %mg-opt %s --convert-mg-to-affine | %FileCheck %s
// CHECK-LABEL: func.func @add_dyn
// CHECK: arith.cmpi eq
// CHECK-NEXT: cf.assert {{.*}}, "mg.add: operand shapes differ at runtime in dimension 0"
// CHECK: arith.cmpi eq
// CHECK-NEXT: cf.assert {{.*}}, "mg.add: operand shapes differ at runtime in dimension 1"
// CHECK: memref.alloc(%{{.*}}, %{{.*}}) : memref<?x?xf64>
// CHECK: affine.for
// CHECK: affine.for
func.func @add_dyn(%a: tensor<?x?xf64>, %b: tensor<?x?xf64>) -> tensor<?x?xf64> {
  %0 = mg.add %a, %b : tensor<?x?xf64>, tensor<?x?xf64> -> tensor<?x?xf64>
  func.return %0 : tensor<?x?xf64>
}
