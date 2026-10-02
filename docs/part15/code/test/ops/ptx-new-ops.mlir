// Chapter 21: the new ops through the GPU path (compile-only). Several loop nests give several kernels.
// RUN: %mgc21 ptx %ex21/14_gpu_ops.mg | %FileCheck %s --check-prefix=OPS
// RUN: %mgc21 ptx %ex21/13_gpu_matmul.mg | %FileCheck %s --check-prefix=MM
// OPS: .visible .entry f_kernel(
// OPS: sub.rn.f64
// OPS: .visible .entry f_kernel(
// OPS: mul.rn.f64
// OPS: .visible .entry f_kernel(
// OPS: div.rn.f64
// OPS: .visible .entry f_kernel(
// OPS: add.rn.f64
// MM: .visible .entry mm_kernel(
// MM: .visible .entry mm_kernel(
// MM: mul.rn.f64
// MM: add.rn.f64
