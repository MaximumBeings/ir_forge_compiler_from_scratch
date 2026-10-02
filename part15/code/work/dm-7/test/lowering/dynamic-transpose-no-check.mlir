// Chapter 13/14: transpose has one operand, so no shape check; the result extents are swapped dims.
// RUN: %mg-opt %s --convert-mg-to-affine | %FileCheck %s
// CHECK-NOT: cf.assert
// CHECK: memref.dim %arg0, %c1
// CHECK: memref.dim %arg0, %c0
// CHECK: memref.alloc(%{{.*}}, %{{.*}}) : memref<?x?xf64>
// CHECK: affine.load %arg0[%arg{{[0-9]+}}, %arg{{[0-9]+}}]
func.func @t(%a: tensor<?x?xf64>) -> tensor<?x?xf64> {
  %0 = mg.transpose %a : tensor<?x?xf64> to tensor<?x?xf64>
  func.return %0 : tensor<?x?xf64>
}
