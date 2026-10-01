// Chapter 12: with bare pointers the same launch passes 5 parameters instead of 23.
// RUN: %mlir-opt %inputs/add_host_device.mlir --pass-pipeline='builtin.module(func.func(gpu-async-region))' -o %t.async.mlir
// RUN: %mlir-opt %t.async.mlir --gpu-lower-to-nvvm-pipeline="cubin-chip=sm_70 cubin-features=+ptx60 cubin-format=isa kernel-bare-ptr-calling-convention=1" -o %t.pipe.mlir
// RUN: %mlir-translate --mlir-to-llvmir %t.pipe.mlir -o %t.ll
// RUN: %FileCheck %s < %t.ll
// CHECK: call void @mgpuLaunchKernel(ptr %{{.*}}, i64 2, i64 1, i64 1, i64 2, i64 1, i64 1, i32 0, ptr %{{.*}}, ptr %{{.*}}, ptr null, i64 5)
