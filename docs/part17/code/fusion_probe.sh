#!/bin/sh
# Why did --affine-loop-fusion do nothing on the dynamic chain? Narrowing it down with three programs. Output: fusion_probe_out.txt
HERE=$(cd "$(dirname "$0")" && pwd); M=${MG_OPT:-$HERE/../../part14/code/build/mg-opt}; W=$HERE/work; mkdir -p $W
count() { grep -c "affine.for" "$1"; }
for p in chain addadd static_chain; do
  $M $HERE/$p.mlir --convert-mg-to-affine -o $W/$p.affine.mlir
  $M $W/$p.affine.mlir --affine-loop-fusion -o $W/$p.fused.mlir
  printf "%-14s affine.for before fusion: %s   after: %s\n" $p $(count $W/$p.affine.mlir) $(count $W/$p.fused.mlir)
done
echo
echo "partial static shape: ?x2 chain, loops before / after full unroll / after fusion"
$M $HERE/chain2.mlir --convert-mg-to-affine -o $W/chain2.affine.mlir
printf "chain2         before: %s   after unroll-full: %s   after fusion: %s\n" $(count $W/chain2.affine.mlir) \
  $($M $W/chain2.affine.mlir --affine-loop-unroll="unroll-full" | grep -c "affine.for") \
  $($M $W/chain2.affine.mlir --affine-loop-fusion | grep -c "affine.for")
