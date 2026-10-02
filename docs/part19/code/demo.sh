#!/bin/sh
# The same runtime shape mismatch, built two ways, observed under three ways of capturing output. Output: demo_out.txt
# Needs ../../part14/code/build.sh (default lowering) and ./build.sh (this chapter's pass).
HERE=$(cd "$(dirname "$0")" && pwd); D=$HERE/../..; W=$HERE/work/demo; mkdir -p $W
OLD=$D/part14/code/build/mg-opt; NEW=$HERE/build/mg-opt
LOW='--lower-affine --convert-scf-to-cf --convert-arith-to-llvm --finalize-memref-to-llvm --convert-func-to-llvm --reconcile-unrealized-casts'
LOWNEW='--lower-affine --convert-scf-to-cf --mg-lower-assert-to-stderr --convert-arith-to-llvm --finalize-memref-to-llvm --convert-func-to-llvm --reconcile-unrealized-casts'
SRC=$D/part13/code/both.mlir; H=$D/part13/code/harness_mismatch.c
build() {  # name mg-opt lowering
  $2 $SRC --convert-mg-to-affine $3 -o $W/$1.mlir && mlir-translate-18 --mlir-to-llvmir $W/$1.mlir -o $W/$1.ll &&
  clang-18 -c $W/$1.ll -o $W/$1.o 2>/dev/null && clang-18 $H $W/$1.o -o $W/$1.exe
}
build old $OLD "$LOW"; build new $NEW "$LOWNEW"
for v in old new; do
  case $v in old) label="Chapter 14 lowering (cf.assert -> puts + abort)";; new) label="Chapter 19 pass (cf.assert -> write(2, ...) + abort)";; esac
  echo "################ $label"
  echo "--- stdout is a PIPE, stderr shown:    (command: ./$v.exe 2>&1 | cat)"
  $W/$v.exe 2>&1 | cat
  echo "--- stdout is a FILE, stderr discarded (command: ./$v.exe > out.txt 2>/dev/null; cat out.txt)"
  $W/$v.exe > $W/$v.out.txt 2>/dev/null; cat $W/$v.out.txt; echo "(stdout file holds $(wc -c < $W/$v.out.txt) bytes)"
  echo "--- stdout discarded, stderr only:      (command: ./$v.exe 2>&1 >/dev/null)"
  $W/$v.exe 2>&1 >/dev/null
  echo "--- exit status of the program itself: $($W/$v.exe >/dev/null 2>&1; echo $?)"
  echo
done
