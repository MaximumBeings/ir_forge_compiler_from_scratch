// Chapter 10: real PTX. 23 kernel parameters (three memrefs expanded into 7 scalars each, plus 2 indices),
// 64-bit index arithmetic, two global f64 loads, one add, one store.
// RUN: %mg-opt %inputs/static_add.mlir --convert-mg-to-affine | %mlir-opt %to-gpu | %mlir-opt --pass-pipeline='builtin.module(lower-affine,nvvm-attach-target{chip=sm_80 features=+ptx60},gpu.module(convert-gpu-to-nvvm{index-bitwidth=64},reconcile-unrealized-casts))' | %mlir-opt --gpu-module-to-binary="format=isa" -o %t.bin.mlir
// RUN: %decode-ptx %t.bin.mlir | %FileCheck %s
// CHECK: .target sm_70
// CHECK: .visible .entry add_tensors_kernel(
// CHECK-COUNT-23: .param .u64 add_tensors_kernel_param_{{[0-9]+}}
// CHECK-NOT: .param .u64 add_tensors_kernel_param_
// CHECK: mov.u32 %{{.*}}, %ctaid.x;
// CHECK: mov.u32 %{{.*}}, %tid.x;
// CHECK: mul.lo.s64
// CHECK: ld.global.f64
// CHECK: ld.global.f64
// CHECK: add.rn.f64
// CHECK: st.global.f64
// CHECK: ret;
