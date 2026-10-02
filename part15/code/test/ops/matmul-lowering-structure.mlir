// Static matmul: a zero-fill nest and a three-deep accumulate nest, no run-time check.
// RUN: %mg-opt %s --convert-mg-to-affine | %FileCheck %s --check-prefix=STATIC
// Dynamic inner dimension: one cf.assert with the documented message.
// RUN: %mg-opt %s --convert-mg-to-affine | %FileCheck %s --check-prefix=ANY
// STATIC-LABEL: func.func @static
// STATIC-NOT: cf.assert
// STATIC: affine.for
// STATIC: affine.store %cst
// STATIC: affine.for
// STATIC-NEXT: affine.for
// STATIC-NEXT: affine.for
// STATIC: arith.mulf
// STATIC: arith.addf
// ANY-LABEL: func.func @dynamic
// ANY: cf.assert %{{.*}}, "mg.matmul: inner dimensions differ at runtime"
func.func @static(%a: tensor<2x3xf64>, %b: tensor<3x4xf64>) -> tensor<2x4xf64> {
  %0 = mg.matmul %a, %b : tensor<2x3xf64>, tensor<3x4xf64> -> tensor<2x4xf64>
  func.return %0 : tensor<2x4xf64>
}
func.func @dynamic(%a: tensor<?x?xf64>, %b: tensor<?x?xf64>) -> tensor<?x?xf64> {
  %0 = mg.matmul %a, %b : tensor<?x?xf64>, tensor<?x?xf64> -> tensor<?x?xf64>
  func.return %0 : tensor<?x?xf64>
}
