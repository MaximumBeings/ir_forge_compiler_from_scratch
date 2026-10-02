#!/bin/sh
# Chapter 10's first attempt at the affine->gpu step (--convert-affine-for-to-gpu), saved verbatim. Output: false_starts_out.txt
cd "$(dirname "$0")"
echo '$ mlir-opt-18 add_affine.mlir --convert-affine-for-to-gpu="gpu-block-dims=1 gpu-thread-dims=1"'
mlir-opt-18 add_affine.mlir --convert-affine-for-to-gpu="gpu-block-dims=1 gpu-thread-dims=1" 2>&1 | cut -c1-200
echo
echo "\$ mlir-opt-18 add_affine.mlir --pass-pipeline='builtin.module(func.func(convert-affine-for-to-gpu{gpu-block-dims=1 gpu-thread-dims=1}))'"
mlir-opt-18 add_affine.mlir --pass-pipeline='builtin.module(func.func(convert-affine-for-to-gpu{gpu-block-dims=1 gpu-thread-dims=1}))' 2>&1 | head -3 | cut -c1-200
