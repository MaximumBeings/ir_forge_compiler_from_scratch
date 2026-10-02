// The loop order is visible in the lowered code. For a 2x3 @ 3x4 product the accumulate nest is 2,4,3 deep-to-inner for ijk (the
// reduction k innermost) and 2,3,4 for ikj (j innermost: it walks along rows of the result and of the right-hand matrix).
// RUN: %mg-opt %s --convert-mg-to-affine | %FileCheck %s --check-prefix=IJK
// RUN: %mg-opt %s --convert-mg-to-affine=matmul-order=ijk | %FileCheck %s --check-prefix=IJK
// RUN: %mg-opt %s --convert-mg-to-affine=matmul-order=ikj | %FileCheck %s --check-prefix=IKJ
// IJK: affine.for %{{.*}} = 0 to 2 {
// IJK: affine.for %{{.*}} = 0 to 4 {
// IJK: affine.for %{{.*}} = 0 to 3 {
// IJK: arith.mulf
// IKJ: affine.for %{{.*}} = 0 to 2 {
// IKJ: affine.for %{{.*}} = 0 to 4 {
// IKJ: affine.store
// IKJ: affine.for %{{.*}} = 0 to 2 {
// IKJ: affine.for %{{.*}} = 0 to 3 {
// IKJ: affine.for %{{.*}} = 0 to 4 {
// IKJ: arith.mulf
func.func @mm(%a: tensor<2x3xf64>, %b: tensor<3x4xf64>) -> tensor<2x4xf64> {
  %0 = mg.matmul %a, %b : tensor<2x3xf64>, tensor<3x4xf64> -> tensor<2x4xf64>
  func.return %0 : tensor<2x4xf64>
}
