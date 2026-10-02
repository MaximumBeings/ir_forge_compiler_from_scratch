// Chapter 12: kernel-bare-ptr-calling-convention=1 cuts the kernel from 23 parameters to 5 (static shapes only).
// RUN: %mlir-opt %inputs/add_host_device.mlir --pass-pipeline='builtin.module(func.func(gpu-async-region))' -o %t.async.mlir
// RUN: %mlir-opt %t.async.mlir --gpu-lower-to-nvvm-pipeline="cubin-chip=sm_70 cubin-features=+ptx60 cubin-format=isa kernel-bare-ptr-calling-convention=1" -o %t.bin.mlir
// RUN: %decode-ptx %t.bin.mlir | %FileCheck %s
// CHECK-COUNT-5: .param .u64 add_tensors_kernel_param_{{[0-9]+}}
// CHECK-NOT: .param .u64 add_tensors_kernel_param_
// CHECK: ld.global.f64
// CHECK: add.rn.f64
// CHECK: st.global.f64
