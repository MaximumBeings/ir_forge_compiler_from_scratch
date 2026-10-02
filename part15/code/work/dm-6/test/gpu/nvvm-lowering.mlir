// Chapter 10: the kernel lowered to the nvvm dialect: special-register reads, an nvvm.kernel llvm.func, a chip target.
// RUN: %mg-opt %inputs/static_add.mlir --convert-mg-to-affine | %mlir-opt %to-gpu | %mlir-opt --pass-pipeline='builtin.module(lower-affine,nvvm-attach-target{chip=sm_70 features=+ptx60},gpu.module(convert-gpu-to-nvvm{index-bitwidth=64},reconcile-unrealized-casts))' | %FileCheck %s
// CHECK: gpu.module @add_tensors_kernel [#nvvm.target<chip = "sm_70">]
// CHECK: llvm.func @add_tensors_kernel(
// CHECK-SAME: attributes {gpu.kernel, nvvm.kernel}
// CHECK: nvvm.read.ptx.sreg.ctaid.x
// CHECK: nvvm.read.ptx.sreg.tid.x
// CHECK: llvm.fadd
