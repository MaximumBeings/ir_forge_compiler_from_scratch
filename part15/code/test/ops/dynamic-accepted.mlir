// With ? dimensions the verifier accepts (the check moves to run time), and the ops round-trip.
// RUN: %mg-opt %s | %FileCheck %s
// CHECK: mg.matmul %{{.*}}, %{{.*}} : tensor<?x?xf64>, tensor<3x?xf64> -> tensor<?x?xf64>
// CHECK: mg.scalar %{{.*}} {op = "div", reversed = true, value = 1.000000e+00 : f64} : tensor<?x?xf64> -> tensor<?x?xf64>
func.func @f(%a: tensor<?x?xf64>, %b: tensor<3x?xf64>) -> tensor<?x?xf64> {
  %0 = mg.matmul %a, %b : tensor<?x?xf64>, tensor<3x?xf64> -> tensor<?x?xf64>
  %1 = mg.scalar %0 {op = "div", value = 1.0 : f64, reversed = true} : tensor<?x?xf64> -> tensor<?x?xf64>
  func.return %1 : tensor<?x?xf64>
}
