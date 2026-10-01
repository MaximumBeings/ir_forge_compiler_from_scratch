#!/bin/sh
# Chapter 13's checks, in order. Run ./build.sh first.
HERE=$(cd "$(dirname "$0")" && pwd); M=$HERE/build/mg-opt; D=$HERE/../..; W=$HERE/work; mkdir -p $W; cd $W
LOW='--lower-affine --convert-scf-to-cf --convert-arith-to-llvm --finalize-memref-to-llvm --convert-func-to-llvm --reconcile-unrealized-casts'
echo "### 1. mixed ?x2 + 3x2 add now verifies:";  $M ../mixed_add.mlir 2>&1 | sed -n 3p
echo "### 2. unranked tensors get an explicit diagnostic:"; $M ../unranked.mlir 2>&1 | head -1; $M ../unranked_add.mlir 2>&1 | head -1
echo "### 3. canonicalizer: mixed types left alone, exact types still fold:"
$M ../tt.mlir --canonicalize | sed -n 3,5p; $M $HERE/tt2.mlir --canonicalize | sed -n 3p
echo "### 4. static output byte-identical to Chapter 10's:"
$M $D/part10/code/add_tensors.mlir --convert-mg-to-affine | cmp - $D/part10/code/add_affine.mlir && echo IDENTICAL
echo "### 5. dynamic add to affine:"; $M ../dyn_add.mlir --convert-mg-to-affine
$M ../both.mlir --convert-mg-to-affine $LOW -o a_llvm.mlir
$M ../both.mlir --one-shot-bufferize="bufferize-function-boundaries" -o b_buf.mlir
$M b_buf.mlir $LOW -o b_llvm.mlir
for p in a b; do mlir-translate-18 --mlir-to-llvmir ${p}_llvm.mlir -o $p.ll; clang-18 -c $p.ll -o $p.o 2>/dev/null; done
clang-18 ../harness_dyn.c a.o -o run_a;               echo "### 6. native run, path A (Chapter 4/5 conversion):"; ./run_a
clang-18 -DSTRIDED ../harness_dyn.c b.o -o run_b;     echo "### 7. native run, path B (Chapter 6 bufferization) + column-major view:"; ./run_b
clang-18 ../harness_mismatch.c a.o -o mism;           echo "### 8. KNOWN GAP, runtime shape mismatch (a=2x3, b=1x2):"; ./mism
