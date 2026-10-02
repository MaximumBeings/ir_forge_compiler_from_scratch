#!/bin/sh
# Chapter 4: the commands this chapter shows, run in order. Intermediate files go to ./work/.
# Needs ./build.sh first.
HERE=$(cd "$(dirname "$0")" && pwd); cd $HERE; W=$HERE/work; mkdir -p $W
MG=$HERE/build/mg-opt
echo "--- add_tensors.mlir --convert-mg-to-affine"; $MG add_tensors.mlir --convert-mg-to-affine
echo "--- mountain_goat.mlir --convert-mg-to-affine"; $MG mountain_goat.mlir --convert-mg-to-affine
echo "--- mountain_goat.mlir --canonicalize --convert-mg-to-affine"; $MG mountain_goat.mlir --canonicalize --convert-mg-to-affine
echo "--- mountain_goat.mlir --one-shot-bufferize (expected to fail in this chapter: no BufferizableOpInterface yet)"; $MG mountain_goat.mlir --one-shot-bufferize || echo "(failed, exit status $?)"
