// Chapter 10: the CUDA-style comparison kernel compiles with clang-18 (no CUDA SDK) to PTX with 3 parameters.
// RUN: %clang -x cuda --cuda-device-only --cuda-gpu-arch=sm_70 -nocudainc -nocudalib -S -O1 %inputs/cuda_add.cu -o %t.ptx
// RUN: %FileCheck %s < %t.ptx
// CHECK: .visible .entry add_cuda(
// CHECK-COUNT-3: .param .u64 add_cuda_param_{{[0-9]+}}
// CHECK-NOT: .param .u64 add_cuda_param_
// CHECK: ld.global.f64
// CHECK: add.f64
// CHECK: st.global.f64
