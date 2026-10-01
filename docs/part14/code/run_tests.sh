#!/bin/sh
# Chapter 14's checks. Run ./build.sh first. Inputs are Chapter 13's, reused unchanged.
HERE=$(cd "$(dirname "$0")" && pwd); M=$HERE/build/mg-opt; P13=$HERE/../../part13/code; D=$HERE/../..; W=$HERE/work; mkdir -p $W; cd $W
LOW='--lower-affine --convert-scf-to-cf --convert-arith-to-llvm --finalize-memref-to-llvm --convert-func-to-llvm --reconcile-unrealized-casts'
echo "### 1. static output still byte-identical to Chapter 10's:"
$M $D/part10/code/add_tensors.mlir --convert-mg-to-affine | cmp - $D/part10/code/add_affine.mlir && echo IDENTICAL
echo "### 2. the emitted check, dynamic add (path A):"
$M $P13/dyn_add.mlir --convert-mg-to-affine | grep -E "cmpi|cf.assert"
echo "### 3. mixed ?x2 + 3x2: only the dimension that is dynamic is checked:"
$M $P13/mixed_add.mlir --convert-mg-to-affine | grep -E "cf.assert"
echo "### 4. same check from path B (One-Shot Bufferize):"
$M $P13/dyn_add.mlir --one-shot-bufferize="bufferize-function-boundaries" | grep -E "cf.assert"
$M $P13/both.mlir --convert-mg-to-affine $LOW -o a_llvm.mlir
$M $P13/both.mlir --one-shot-bufferize="bufferize-function-boundaries" -o b_buf.mlir; $M b_buf.mlir $LOW -o b_llvm.mlir
$M $P13/mixed_add.mlir --convert-mg-to-affine $LOW -o m_llvm.mlir
for p in a b m; do mlir-translate-18 --mlir-to-llvmir ${p}_llvm.mlir -o $p.ll; clang-18 -c $p.ll -o $p.o 2>/dev/null; done
clang-18 $P13/harness_dyn.c a.o -o run_a;            echo "### 5. valid shapes, path A (compared automatically with Chapter 13's recorded output):"; ./run_a > outA.txt
sed -n '/^### 6\./,/^### 7\./p' $P13/run_out.txt | sed '1d;$d' | cmp - outA.txt && echo "MATCHES Chapter 13 (path A)"
clang-18 -DSTRIDED $P13/harness_dyn.c b.o -o run_b;  echo "### 6. valid shapes, path B + column-major view (compared automatically with Chapter 13's recorded output):"; ./run_b > outB.txt
sed -n '/^### 7\./,/^### 8\./p' $P13/run_out.txt | sed '1d;$d' | cmp - outB.txt && echo "MATCHES Chapter 13 (path B)"
clang-18 $P13/harness_mismatch.c a.o -o mism_a; clang-18 $P13/harness_mismatch.c b.o -o mism_b
echo "### 7. runtime mismatch (a=2x3, b=1x2), path A, stdout line-buffered so the message survives:"
stdbuf -oL ./mism_a 2>&1; echo "exit code $?"
echo "### 8. same, path B:"; stdbuf -oL ./mism_b 2>&1; echo "exit code $?"
echo "### 9. same, path A, stdout is a pipe (default full buffering): is the message printed?"
./mism_a 2>&1 | cat; echo "(pipeline end; abort exit code of the program itself: $(./mism_a >/dev/null 2>&1; echo $?))"
clang-18 $HERE/harness_mixed.c m.o -o mixed_run
echo "### 10. mixed ?x2 + 3x2, matching (a has 3 rows):"; ./mixed_run 3
echo "### 11. mixed ?x2 + 3x2, mismatched (a has 2 rows):"; stdbuf -oL ./mixed_run 2 2>&1; echo "exit code $?"
