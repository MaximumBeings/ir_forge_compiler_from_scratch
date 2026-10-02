// mg.broadcast can only grow a dimension from size 1, and only for static shapes.
// RUN: %not %mg-opt %s --split-input-file 2>&1 | %FileCheck %s
// CHECK-DAG: error: 'mg.broadcast' op mg.broadcast: dimension 1 of 'tensor<2x3xf64>' can only grow from size 1, not to 'tensor<2x5xf64>'
// CHECK-DAG: error: 'mg.broadcast' op mg.broadcast needs static shapes (dynamic broadcasting is not supported)
func.func @a(%x: tensor<2x3xf64>) -> tensor<2x5xf64> {
  %0 = mg.broadcast %x : tensor<2x3xf64> -> tensor<2x5xf64>
  func.return %0 : tensor<2x5xf64>
}
// -----
func.func @b(%x: tensor<?x3xf64>) -> tensor<2x3xf64> {
  %0 = mg.broadcast %x : tensor<?x3xf64> -> tensor<2x3xf64>
  func.return %0 : tensor<2x3xf64>
}
