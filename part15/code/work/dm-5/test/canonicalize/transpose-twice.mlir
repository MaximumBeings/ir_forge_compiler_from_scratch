// Chapter 3: transpose(transpose(x)) -> x.
// RUN: %mg-opt %s --canonicalize | %FileCheck %s
// CHECK: func.func @tt
// CHECK-NOT: mg.transpose
// CHECK: return %arg0 : tensor<2x3xf64>
func.func @tt(%a: tensor<2x3xf64>) -> tensor<2x3xf64> {
  %0 = mg.transpose %a : tensor<2x3xf64> to tensor<3x2xf64>
  %1 = mg.transpose %0 : tensor<3x2xf64> to tensor<2x3xf64>
  func.return %1 : tensor<2x3xf64>
}
