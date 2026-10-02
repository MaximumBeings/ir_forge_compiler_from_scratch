// Chapter 20: the GPU path from surface syntax: PTX comes out (compile-only; nothing is launched).
// RUN: %mgc ptx %ex/05_gpu.mg | %FileCheck %s
// CHECK: .target sm_70
// CHECK: .visible .entry add_kernel(
// CHECK: ld.global.f64
// CHECK: ld.global.f64
// CHECK: add.rn.f64
// CHECK: st.global.f64
