// Chapter 13: dynamic extents verify, including a mixed ?x2 + 3x2 add.
// RUN: %mg-opt %s | %FileCheck %s
// CHECK-LABEL: func.func @dyn
// CHECK: mg.add %arg0, %arg1 : tensor<?x?xf64>, tensor<?x?xf64> -> tensor<?x?xf64>
// CHECK-LABEL: func.func @mixed
// CHECK: mg.add %arg0, %arg1 : tensor<?x2xf64>, tensor<3x2xf64> -> tensor<?x2xf64>
// CHECK-LABEL: func.func @t
// CHECK: mg.transpose %arg0 : tensor<?x?xf64> to tensor<?x?xf64>
func.func @dyn(%a: tensor<?x?xf64>, %b: tensor<?x?xf64>) -> tensor<?x?xf64> {
  %0 = mg.add %a, %b : tensor<?x?xf64>, tensor<?x?xf64> -> tensor<?x?xf64>
  func.return %0 : tensor<?x?xf64>
}
func.func @mixed(%a: tensor<?x2xf64>, %b: tensor<3x2xf64>) -> tensor<?x2xf64> {
  %0 = mg.add %a, %b : tensor<?x2xf64>, tensor<3x2xf64> -> tensor<?x2xf64>
  func.return %0 : tensor<?x2xf64>
}
func.func @t(%a: tensor<?x?xf64>) -> tensor<?x?xf64> {
  %0 = mg.transpose %a : tensor<?x?xf64> to tensor<?x?xf64>
  func.return %0 : tensor<?x?xf64>
}
