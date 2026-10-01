// Chapter 6 + 13 + 14: the One-Shot Bufferize path emits the same dynamic structure and the same checks.
// RUN: %mg-opt %s --one-shot-bufferize="bufferize-function-boundaries" | %FileCheck %s
// CHECK: func.func @add_dyn(%arg0: memref<?x?xf64, strided<[?, ?], offset: ?>>, %arg1: memref<?x?xf64, strided<[?, ?], offset: ?>>) -> memref<?x?xf64>
// CHECK: cf.assert {{.*}}, "mg.add: operand shapes differ at runtime in dimension 0"
// CHECK: cf.assert {{.*}}, "mg.add: operand shapes differ at runtime in dimension 1"
// CHECK: memref.alloc(%{{.*}}, %{{.*}}) : memref<?x?xf64>
func.func @add_dyn(%a: tensor<?x?xf64>, %b: tensor<?x?xf64>) -> tensor<?x?xf64> {
  %0 = mg.add %a, %b : tensor<?x?xf64>, tensor<?x?xf64> -> tensor<?x?xf64>
  func.return %0 : tensor<?x?xf64>
}
