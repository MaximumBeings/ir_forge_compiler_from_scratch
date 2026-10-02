#!/bin/sh
# Chapter 2: the commands this chapter shows, run in order. Intermediate files go to ./work/.
# Needs ./build.sh first (builds ./build/mg-opt).
HERE=$(cd "$(dirname "$0")" && pwd); cd $HERE; W=$HERE/work; mkdir -p $W
MG=$HERE/build/mg-opt
echo "--- mountain_goat.mlir (valid)"; $MG mountain_goat.mlir
echo "--- bad_transpose.mlir (must be rejected)"; $MG bad_transpose.mlir || echo "(rejected, exit status $?)"
echo "--- mismatched_add.mlir (accepted in this chapter: no shape check yet)"; $MG mismatched_add.mlir || echo "(rejected, exit status $?)"
