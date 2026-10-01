// Chapter 13: with dynamic extents the rewrite still fires when the types match exactly.
// RUN: %mg-opt %s --canonicalize | %FileCheck %s
// CHECK-NOT: mg.transpose
// CHECK: return %arg0 : tensor<?x2xf64>
func.func @tt(%a: tensor<?x2xf64>) -> tensor<?x2xf64> {
  %0 = mg.transpose %a : tensor<?x2xf64> to tensor<2x?xf64>
  %1 = mg.transpose %0 : tensor<2x?xf64> to tensor<?x2xf64>
  func.return %1 : tensor<?x2xf64>
}
