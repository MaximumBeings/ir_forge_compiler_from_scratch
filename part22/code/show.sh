#!/bin/sh
# The lowered form of the new ops, for the chapter to explain. Output: show/
HERE=$(cd "$(dirname "$0")" && pwd); O=$HERE/show; mkdir -p $O; M=$HERE/build/mg-opt
cat > $O/reduce_row_sum.mlir <<'MLIR'
func.func @f(%a: tensor<2x3xf64>) -> tensor<2x1xf64> {
  %0 = mg.reduce %a {axis = 1 : i64, kind = "sum"} : tensor<2x3xf64> -> tensor<2x1xf64>
  func.return %0 : tensor<2x1xf64>
}
MLIR
cat > $O/broadcast_row.mlir <<'MLIR'
func.func @f(%a: tensor<1x3xf64>) -> tensor<2x3xf64> {
  %0 = mg.broadcast %a : tensor<1x3xf64> -> tensor<2x3xf64>
  func.return %0 : tensor<2x3xf64>
}
MLIR
for n in reduce_row_sum broadcast_row; do $M $O/$n.mlir --convert-mg-to-affine -o $O/${n}_lowered.mlir; done
HERE_EX=$HERE/examples; $HERE/mgc mlir $HERE_EX/07_mlp_layer.mg > $O/mlp_layer_front_end.mlir
