#!/bin/sh
# Chapter 42: the time of every pass of the lowering stage for the 200-step training program (190,636 loop nests in one function), with MLIR's own --mlir-timing report,
# for --convert-scf-to-cf and for --mg-scf-to-cf-reverse. The first takes about 35 minutes: run it in the background. Output: pass_times_200_out.txt
HERE=$(cd "$(dirname "$0")" && pwd); W=$HERE/work; mkdir -p $W; OPT=$HERE/build/mg-opt
python3 $HERE/mgfront.py $HERE/../../part36/code/examples/04_train_200_steps.mg > $W/t200.mlir && $OPT $W/t200.mlir --convert-mg-to-affine -o $W/t200.affine.mlir
for SCF in --mg-scf-to-cf-reverse --convert-scf-to-cf; do
  echo "################ $SCF"
  $OPT $W/t200.affine.mlir --lower-affine $SCF --mg-lower-assert-to-stderr --convert-math-to-llvm --convert-arith-to-llvm --finalize-memref-to-llvm --convert-func-to-llvm --reconcile-unrealized-casts --mlir-timing -o /dev/null 2>&1 | grep -v "^===\|^$\|Execution time\|Wall Time"
done
