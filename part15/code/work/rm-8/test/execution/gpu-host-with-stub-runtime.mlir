// Chapter 11/12: the lowered host code, linked with a CPU STUB runtime, prints the right answer, with both the
// 23-parameter and the 5-parameter launch. This tests the host glue; it does NOT execute the PTX.
// RUN: %mlir-opt %inputs/add_host_device.mlir --pass-pipeline='builtin.module(func.func(gpu-async-region))' -o %t.async.mlir
// RUN: %mlir-opt %t.async.mlir --gpu-lower-to-nvvm-pipeline="cubin-chip=sm_70 cubin-features=+ptx60 cubin-format=isa" -o %t.p23.mlir
// RUN: %mlir-translate --mlir-to-llvmir %t.p23.mlir -o %t.p23.ll
// RUN: %clang -c %t.p23.ll -o %t.p23.o
// RUN: %clang %inputs/static_harness.c %t.p23.o %inputs/stub_gpu_runtime.c -o %t.p23.exe
// RUN: %t.p23.exe 2>%t.p23.err | %FileCheck %s
// RUN: %FileCheck %s --check-prefix=LAUNCH23 < %t.p23.err
// RUN: %mlir-opt %t.async.mlir --gpu-lower-to-nvvm-pipeline="cubin-chip=sm_70 cubin-features=+ptx60 cubin-format=isa kernel-bare-ptr-calling-convention=1" -o %t.p5.mlir
// RUN: %mlir-translate --mlir-to-llvmir %t.p5.mlir -o %t.p5.ll
// RUN: %clang -c %t.p5.ll -o %t.p5.o
// RUN: %clang %inputs/static_harness.c %t.p5.o %inputs/stub_gpu_runtime.c -o %t.p5.exe
// RUN: %t.p5.exe 2>%t.p5.err | %FileCheck %s
// RUN: %FileCheck %s --check-prefix=LAUNCH5 < %t.p5.err
// CHECK: 6 8
// CHECK-NEXT: 10 12
// LAUNCH23: [stub] module load: optLevel=2, PTX has .entry add_tensors_kernel: yes
// LAUNCH23: [stub] launch add_tensors_kernel: grid=(2,1,1) block=(2,1,1) nparams=23
// LAUNCH5: [stub] launch add_tensors_kernel: grid=(2,1,1) block=(2,1,1) nparams=5
