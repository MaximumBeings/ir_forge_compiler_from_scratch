#!/bin/sh
# The accumulate loop nest of a 2x3 @ 3x4 product in each loop order. Output: show/loop_orders.txt
HERE=$(cd "$(dirname "$0")" && pwd); O=$HERE/show; mkdir -p $O
cat > $O/mm.mlir <<'MLIR'
func.func @mm(%a: tensor<2x3xf64>, %b: tensor<3x4xf64>) -> tensor<2x4xf64> {
  %0 = mg.matmul %a, %b : tensor<2x3xf64>, tensor<3x4xf64> -> tensor<2x4xf64>
  func.return %0 : tensor<2x4xf64>
}
MLIR
for o in ijk ikj; do
  echo "### matmul-order=$o  (the zero-fill nest is omitted; this is the accumulate nest)"
  $HERE/build/mg-opt $O/mm.mlir --convert-mg-to-affine=matmul-order=$o | sed -n '/arith.constant 0 : index/,$p' | grep -v "arith.constant" | sed '/return/,$d'
done > $O/loop_orders.txt
