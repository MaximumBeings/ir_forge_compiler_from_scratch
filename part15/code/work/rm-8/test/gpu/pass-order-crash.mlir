// Chapter 12: PINS A KNOWN LLVM 18.1.3 BUG. gpu-to-llvm after gpu-module-to-binary segfaults mlir-opt (the launch
// pattern looks the kernel module up as a gpu::GPUModuleOp, which has already become a gpu.binary). If a newer
// toolchain fixes this, this test starts failing: that is the signal to revisit Chapters 11 and 12, not a regression.
// RUN: %mlir-opt %inputs/add_host_device.mlir --pass-pipeline='builtin.module(func.func(gpu-async-region))' -o %t.async.mlir
// RUN: %not --crash %mlir-opt %t.async.mlir --pass-pipeline='builtin.module(lower-affine,nvvm-attach-target{chip=sm_70 features=+ptx60},gpu.module(convert-gpu-to-nvvm{index-bitwidth=64},reconcile-unrealized-casts),gpu-module-to-binary{format=isa},gpu-to-llvm)' -o /dev/null
