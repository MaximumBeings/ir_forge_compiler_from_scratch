#!/bin/sh
# Chapter 3: the commands this chapter shows, run in order. Intermediate files go to ./work/.
# Needs ./build.sh first.
HERE=$(cd "$(dirname "$0")" && pwd); cd $HERE; W=$HERE/work; mkdir -p $W
MG=$HERE/build/mg-opt
echo "--- mismatched_add.mlir (now rejected)"; $MG mismatched_add.mlir || echo "(rejected, exit status $?)"
echo "--- canonicalize_demo.mlir, as written"; $MG canonicalize_demo.mlir
echo "--- canonicalize_demo.mlir --canonicalize"; $MG canonicalize_demo.mlir --canonicalize
