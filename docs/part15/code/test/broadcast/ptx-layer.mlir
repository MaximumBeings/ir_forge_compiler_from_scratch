// The GPU path for broadcast + add + relu + a row reduction: five kernels, a NaN-propagating max, a sequential reduction.
// RUN: %mgc22 ptx %ex22/10_gpu_layer.mg | %FileCheck %s
// CHECK: .visible .entry f_kernel(
// CHECK: .visible .entry f_kernel(
// CHECK: add.rn.f64
// CHECK: .visible .entry f_kernel(
// CHECK: max.NaN.f64
// CHECK: .visible .entry f_kernel(
// CHECK: .visible .entry f_kernel(
// CHECK: add.rn.f64
// CHECK: add.rn.f64
// CHECK: add.rn.f64
