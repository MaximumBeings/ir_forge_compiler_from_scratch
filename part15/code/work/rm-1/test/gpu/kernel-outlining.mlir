// Chapter 10: mg.add -> affine -> a real gpu.module kernel, 2 blocks x 2 threads, one element per thread.
// RUN: %mg-opt %inputs/static_add.mlir --convert-mg-to-affine | %mlir-opt %to-gpu | %FileCheck %s
// CHECK: gpu.launch_func @add_tensors_kernel::@add_tensors_kernel blocks in (%{{.*}}, %{{.*}}, %{{.*}}) threads in (%{{.*}}, %{{.*}}, %{{.*}})
// CHECK: gpu.module @add_tensors_kernel
// CHECK: gpu.func @add_tensors_kernel(%{{.*}}: index, %{{.*}}: index, %{{.*}}: memref<2x2xf64>, %{{.*}}: memref<2x2xf64>, %{{.*}}: memref<2x2xf64>) kernel
// CHECK: gpu.block_id x
// CHECK: gpu.thread_id x
// CHECK: memref.load
// CHECK: memref.load
// CHECK: arith.addf
// CHECK: memref.store
// CHECK: gpu.return
