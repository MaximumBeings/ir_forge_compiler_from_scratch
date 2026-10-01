// Chapter 3: AddOp::fold folds two constants into one.
// RUN: %mg-opt %s --canonicalize | %FileCheck %s
// CHECK: mg.constant dense<{{\[\[}}6.000000e+00, 8.000000e+00], [1.000000e+01, 1.200000e+01]]> : tensor<2x2xf64>
// CHECK-NOT: mg.add
func.func @main() {
  %a = mg.constant dense<[[1.0, 2.0], [3.0, 4.0]]> : tensor<2x2xf64>
  %b = mg.constant dense<[[5.0, 6.0], [7.0, 8.0]]> : tensor<2x2xf64>
  %s = mg.add %a, %b : tensor<2x2xf64>, tensor<2x2xf64> -> tensor<2x2xf64>
  mg.print %s : tensor<2x2xf64>
  func.return
}
