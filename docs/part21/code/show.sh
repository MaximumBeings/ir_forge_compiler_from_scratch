#!/bin/sh
# The lowered form of the new ops, for the chapter to explain. Output: show/
HERE=$(cd "$(dirname "$0")" && pwd); O=$HERE/show; mkdir -p $O; M=$HERE/build/mg-opt
cat > $O/matmul_static.mlir <<'MLIR'
func.func @mm(%a: tensor<2x3xf64>, %b: tensor<3x4xf64>) -> tensor<2x4xf64> {
  %0 = mg.matmul %a, %b : tensor<2x3xf64>, tensor<3x4xf64> -> tensor<2x4xf64>
  func.return %0 : tensor<2x4xf64>
}
MLIR
cat > $O/scalar_reversed.mlir <<'MLIR'
func.func @f(%a: tensor<2x2xf64>) -> tensor<2x2xf64> {
  %0 = mg.scalar %a {op = "sub", value = 10.0 : f64, reversed = true} : tensor<2x2xf64> -> tensor<2x2xf64>
  func.return %0 : tensor<2x2xf64>
}
MLIR
cat > $O/matmul_dynamic.mlir <<'MLIR'
func.func @mm(%a: tensor<?x?xf64>, %b: tensor<?x?xf64>) -> tensor<?x?xf64> {
  %0 = mg.matmul %a, %b : tensor<?x?xf64>, tensor<?x?xf64> -> tensor<?x?xf64>
  func.return %0 : tensor<?x?xf64>
}
MLIR
for n in matmul_static scalar_reversed matmul_dynamic; do $M $O/$n.mlir --convert-mg-to-affine -o $O/${n}_lowered.mlir; done
