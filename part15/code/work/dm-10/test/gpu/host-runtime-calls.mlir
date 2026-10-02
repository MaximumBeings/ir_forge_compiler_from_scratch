// Chapter 11: gpu.launch_func becomes mgpu* runtime calls at mlir-translate time; grid 2x1x1, block 2x1x1, 23 params.
// RUN: %mlir-opt %inputs/add_host_device.mlir --pass-pipeline='builtin.module(func.func(gpu-async-region))' -o %t.async.mlir
// RUN: %mlir-opt %t.async.mlir --gpu-lower-to-nvvm-pipeline="cubin-chip=sm_70 cubin-features=+ptx60 cubin-format=isa" -o %t.pipe.mlir
// RUN: %mlir-translate --mlir-to-llvmir %t.pipe.mlir -o %t.ll
// RUN: %FileCheck %s < %t.ll
// CHECK: call ptr @mgpuStreamCreate
// CHECK-COUNT-3: call ptr @mgpuMemAlloc
// CHECK-COUNT-2: call void @mgpuMemcpy
// CHECK: call ptr @mgpuModuleLoadJIT(ptr @add_tensors_kernel_bin_cst, i32 2)
// CHECK: call ptr @mgpuModuleGetFunction
// CHECK: call void @mgpuLaunchKernel(ptr %{{.*}}, i64 2, i64 1, i64 1, i64 2, i64 1, i64 1, i32 0, ptr %{{.*}}, ptr %{{.*}}, ptr null, i64 23)
// CHECK: call void @mgpuModuleUnload
// CHECK: call void @mgpuMemcpy
// CHECK-COUNT-3: call void @mgpuMemFree
