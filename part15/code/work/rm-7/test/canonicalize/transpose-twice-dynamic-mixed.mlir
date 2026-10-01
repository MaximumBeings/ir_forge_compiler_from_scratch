// Chapter 13: the rewrite must NOT fire when it would change the type (it used to emit invalid IR).
// RUN: %mg-opt %s --canonicalize | %FileCheck %s
// CHECK: mg.transpose %arg0 : tensor<?x2xf64> to tensor<2x?xf64>
// CHECK: mg.transpose %0 : tensor<2x?xf64> to tensor<?x?xf64>
// CHECK: return %1 : tensor<?x?xf64>
func.func @tt(%a: tensor<?x2xf64>) -> tensor<?x?xf64> {
  %0 = mg.transpose %a : tensor<?x2xf64> to tensor<2x?xf64>
  %1 = mg.transpose %0 : tensor<2x?xf64> to tensor<?x?xf64>
  func.return %1 : tensor<?x?xf64>
}
