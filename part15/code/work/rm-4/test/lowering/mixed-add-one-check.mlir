// Chapter 14: ?x2 + 3x2 checks only dimension 0 (dimension 1 is static on both sides).
// RUN: %mg-opt %s --convert-mg-to-affine | %FileCheck %s
// CHECK: cf.assert {{.*}}, "mg.add: operand shapes differ at runtime in dimension 0"
// CHECK-NOT: cf.assert
func.func @mixed(%a: tensor<?x2xf64>, %b: tensor<3x2xf64>) -> tensor<?x2xf64> {
  %0 = mg.add %a, %b : tensor<?x2xf64>, tensor<3x2xf64> -> tensor<?x2xf64>
  func.return %0 : tensor<?x2xf64>
}
