// mg.reduce rejects a bad axis, a bad kind, and a result that does not collapse the reduced axis.
// RUN: %not %mg-opt %s --split-input-file 2>&1 | %FileCheck %s
// CHECK-DAG: error: 'mg.reduce' op mg.reduce: axis must be 0 or 1, got 2
// CHECK-DAG: error: 'mg.reduce' op mg.reduce: kind must be sum or max, got 'min'
// CHECK-DAG: error: 'mg.reduce' op mg.reduce: reducing axis 1 of 'tensor<2x3xf64>' must give a result with that axis of size 1, got 'tensor<2x3xf64>'
func.func @a(%x: tensor<2x3xf64>) -> tensor<2x1xf64> {
  %0 = mg.reduce %x {axis = 2 : i64, kind = "sum"} : tensor<2x3xf64> -> tensor<2x1xf64>
  func.return %0 : tensor<2x1xf64>
}
// -----
func.func @b(%x: tensor<2x3xf64>) -> tensor<2x1xf64> {
  %0 = mg.reduce %x {axis = 1 : i64, kind = "min"} : tensor<2x3xf64> -> tensor<2x1xf64>
  func.return %0 : tensor<2x1xf64>
}
// -----
func.func @c(%x: tensor<2x3xf64>) -> tensor<2x3xf64> {
  %0 = mg.reduce %x {axis = 1 : i64, kind = "sum"} : tensor<2x3xf64> -> tensor<2x3xf64>
  func.return %0 : tensor<2x3xf64>
}
