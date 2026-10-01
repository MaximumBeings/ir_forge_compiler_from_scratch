#!/bin/sh
# Chapter 12: the same Chapter 11 pipeline with the kernel bare-pointer calling convention turned on.
# Run from this directory; reuses Chapter 11's inputs (async.mlir is Chapter 11's gpu-async-region output).
set -e
P=../../part11/code
mlir-opt-18 $P/async.mlir \
  --gpu-lower-to-nvvm-pipeline="cubin-chip=sm_70 cubin-features=+ptx60 cubin-format=isa kernel-bare-ptr-calling-convention=1" \
  -o bare_out.mlir
python3 ../../part10/code/decode_ptx.py bare_out.mlir > bare.ptx
mlir-translate-18 --mlir-to-llvmir bare_out.mlir -o bare.ll
echo "kernel .param declarations: $(grep -c '^[[:space:]]*\.param' bare.ptx)"
clang-18 -c bare.ll -o bare.o 2>/dev/null
clang-18 $P/harness.c bare.o $P/stub_gpu_runtime.c -o bare_demo
./bare_demo
