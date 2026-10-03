#!/bin/sh
# Chapter 37: the files mgc produces on the way to machine code, for the smallest program (examples/01_add2x2.mg) and for the 64 x 64 matrix product.
# Prints the size of each stage, and (for the small program) the content of each. Output: stages_out.txt
HERE=$(cd "$(dirname "$0")" && pwd); MGC=$HERE/../../part32/code/mgc; W=$HERE/work/stages; rm -rf $W; mkdir -p $W
show() {  # name file order
  MGC_KEEP=$W/$1 $MGC lib $2 -o $W/$1 -O0 $3 >/dev/null; d=$W/$1; b=$(basename $2 .mg)
  echo "== $1: lines per stage"
  for f in $b.mlir $b.affine.mlir $b.llvm.mlir $b.ll; do printf '   %-22s %4d lines\n' $f $(wc -l < $d/$f); done
}
show add2 $HERE/examples/01_add2x2.mg; show mm_ijk $HERE/examples/02_matmul64.mg; show mm_ikj $HERE/examples/02_matmul64.mg "--matmul-order ikj"
for f in 01_add2x2.mlir 01_add2x2.affine.mlir; do echo; echo "---- add2/$f"; cat $W/add2/$f; done
echo; echo "---- add2/01_add2x2.ll (the whole file, the LLVM IR of the small program)"; cat $W/add2/01_add2x2.ll
