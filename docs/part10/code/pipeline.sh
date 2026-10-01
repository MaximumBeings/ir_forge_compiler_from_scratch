#!/bin/sh
# Chapter 10's whole real pipeline, start to finish. Needs ./mg-opt (Chapter 7's build) on PATH or in cwd.
set -e
MG=${MG:-./mg-opt}
$MG add_tensors.mlir --convert-mg-to-affine -o add_affine.mlir
mlir-opt-18 add_affine.mlir \
  --pass-pipeline='builtin.module(func.func(affine-parallelize,lower-affine,gpu-map-parallel-loops,convert-parallel-loops-to-gpu),gpu-kernel-outlining)' \
  -o add_gpu.mlir
mlir-opt-18 add_gpu.mlir \
  --pass-pipeline='builtin.module(lower-affine,nvvm-attach-target{chip=sm_70 features=+ptx60},gpu.module(convert-gpu-to-nvvm{index-bitwidth=64},reconcile-unrealized-casts))' \
  -o add_nvvm.mlir
mlir-opt-18 add_nvvm.mlir --gpu-module-to-binary="format=isa" -o add_bin.mlir   # PTX text, hex-escaped inside the .mlir
mlir-opt-18 add_gpu.mlir \
  --pass-pipeline='builtin.module(lower-affine,canonicalize,nvvm-attach-target{chip=sm_70 features=+ptx60},gpu.module(convert-gpu-to-nvvm{index-bitwidth=32},reconcile-unrealized-casts),gpu-module-to-binary{format=isa})' \
  -o add_bin32.mlir
clang-18 -x cuda --cuda-device-only --cuda-gpu-arch=sm_70 -nocudainc -nocudalib -S -O1 cuda_add.cu -o cuda_add.ptx
