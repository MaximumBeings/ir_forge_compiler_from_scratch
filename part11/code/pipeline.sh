#!/bin/sh
# Chapter 11: host + device lowering with the real runtime calls, then run against a CPU stub runtime.
# Input: add_host_device.mlir (Chapter 10's kernel module + a hand-written host function using gpu.alloc/memcpy).
set -e
# 1. Make the gpu.* host ops async -- LLVM 18's gpu-to-llvm patterns only match async ops.
mlir-opt-18 add_host_device.mlir --pass-pipeline='builtin.module(func.func(gpu-async-region))' -o async.mlir
# 2. MLIR's own pipeline: kernel -> nvvm -> PTX (gpu.binary), host -> llvm dialect.
mlir-opt-18 async.mlir --gpu-lower-to-nvvm-pipeline="cubin-chip=sm_70 cubin-features=+ptx60 cubin-format=isa" -o pipe_out.mlir
# 3. gpu.launch_func is turned into mgpuModuleLoadJIT / mgpuLaunchKernel calls at LLVM-IR translation time.
mlir-translate-18 --mlir-to-llvmir pipe_out.mlir -o host.ll
# 4. Link with Chapter 8's unmodified harness and the stub runtime, run.
clang-18 -c host.ll -o host.o 2>/dev/null
clang-18 harness.c host.o stub_gpu_runtime.c -o add_tensors_stub_demo
./add_tensors_stub_demo
