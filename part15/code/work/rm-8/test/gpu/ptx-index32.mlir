// Chapter 10: index-bitwidth=32 turns the 64-bit index math into 32-bit (mad.lo.s32), without changing the parameter count.
// RUN: %mg-opt %inputs/static_add.mlir --convert-mg-to-affine | %mlir-opt %to-gpu | %mlir-opt --pass-pipeline='builtin.module(lower-affine,canonicalize,nvvm-attach-target{chip=sm_70 features=+ptx60},gpu.module(convert-gpu-to-nvvm{index-bitwidth=32},reconcile-unrealized-casts),gpu-module-to-binary{format=isa})' -o %t.bin.mlir
// RUN: %decode-ptx %t.bin.mlir | %FileCheck %s
// CHECK-COUNT-23: .param .u{{(32|64)}} add_tensors_kernel_param_{{[0-9]+}}
// CHECK-NOT: .param .u{{(32|64)}} add_tensors_kernel_param_
// CHECK: mad.lo.s32
// CHECK-NOT: mul.lo.s64
// CHECK: ld.global.f64
