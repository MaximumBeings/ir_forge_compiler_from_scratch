// The three ops parse and print, with ? accepted for relu and reduce.
// RUN: %mg-opt %s | %FileCheck %s --check-prefix=RT
// RUN: %mg-opt %s --convert-mg-to-affine | %FileCheck %s --check-prefix=LOW
// RT: mg.relu %{{.*}} : tensor<?x?xf64> -> tensor<?x?xf64>
// RT: mg.reduce %{{.*}} {axis = 0 : i64, kind = "max"} : tensor<?x?xf64> -> tensor<1x?xf64>
// RT: mg.broadcast %{{.*}} : tensor<1x3xf64> -> tensor<2x3xf64>
// LOW-LABEL: func.func @f
// relu's maximumf comes first; then the reduction: a -infinity initial value, a fill nest, an accumulate nest
// with a second maximumf over the INPUT. None of it needs a run-time check.
// LOW-NOT: cf.assert
// LOW: arith.maximumf
// LOW: arith.constant 0xFFF0000000000000 : f64
// LOW: affine.for
// LOW: affine.store
// LOW: affine.for
// LOW: arith.maximumf
// LOW-LABEL: func.func @g
// LOW: arith.constant 0 : index
// LOW: affine.load %arg0[%c0, %arg
// Reducing axis 1 must fold into result[i, 0]: the row index first, then the constant 0. (Writing result[0, i] touches the
// same memory for an Mx1 result, so no test of the numbers could ever notice; only the structure shows it.)
// LOW-LABEL: func.func @h
// LOW: affine.load %alloc[%arg{{[0-9]+}}, %c0{{[_0-9]*}}]
// LOW: affine.store %{{.*}}, %alloc[%arg{{[0-9]+}}, %c0{{[_0-9]*}}]
func.func @f(%x: tensor<?x?xf64>) -> tensor<1x?xf64> {
  %0 = mg.relu %x : tensor<?x?xf64> -> tensor<?x?xf64>
  %1 = mg.reduce %0 {axis = 0 : i64, kind = "max"} : tensor<?x?xf64> -> tensor<1x?xf64>
  func.return %1 : tensor<1x?xf64>
}
func.func @g(%x: tensor<1x3xf64>) -> tensor<2x3xf64> {
  %0 = mg.broadcast %x : tensor<1x3xf64> -> tensor<2x3xf64>
  func.return %0 : tensor<2x3xf64>
}
func.func @h(%x: tensor<2x3xf64>) -> tensor<2x1xf64> {
  %0 = mg.reduce %x {axis = 1 : i64, kind = "sum"} : tensor<2x3xf64> -> tensor<2x1xf64>
  func.return %0 : tensor<2x1xf64>
}
