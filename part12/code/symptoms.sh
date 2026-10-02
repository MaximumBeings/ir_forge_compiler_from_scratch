#!/bin/sh
# Reproduces the three Chapter 11 symptoms that Chapter 12 explains from MLIR's source, saving the real outputs.
# NOTE: the crashes and errors this script reproduces are the SYMPTOMS Chapter 12 explains; they are expected, not regressions.
HERE=$(cd "$(dirname "$0")" && pwd); IN=$HERE/../../part15/code/test/Inputs/add_host_device.mlir; O=$HERE/symptoms; mkdir -p $O
K='nvvm-attach-target{chip=sm_70 features=+ptx60},gpu.module(convert-gpu-to-nvvm{index-bitwidth=64},reconcile-unrealized-casts)'
mlir-opt-18 $IN --pass-pipeline='builtin.module(func.func(gpu-async-region))' -o $O/async.mlir
# 1. gpu-to-llvm AFTER gpu-module-to-binary: the segfault (first lines of the report)
mlir-opt-18 $O/async.mlir --pass-pipeline="builtin.module(lower-affine,$K,gpu-module-to-binary{format=isa},gpu-to-llvm)" -o /dev/null 2>&1 | grep -E "Stack dump|Program arguments|#[0-9] .*(getTargetsAttr|PrintStackTrace)" | cut -c1-170 | sed "s#$HERE/##g" > $O/1_crash_after_binary.txt
# 2. gpu.alloc / gpu.memcpy are NOT lowered unless the ops are async: which gpu ops survive gpu-to-llvm on the NON-async input?
mlir-opt-18 $IN --pass-pipeline="builtin.module(lower-affine,$K,gpu-to-llvm)" -o $O/2_no_async.mlir 2>/dev/null
grep -E "gpu\.(alloc|memcpy|dealloc)" $O/2_no_async.mlir | sed 's/^ *//' > $O/2_survivors_without_async.txt
mlir-opt-18 $O/async.mlir --pass-pipeline="builtin.module(lower-affine,$K,gpu-to-llvm)" -o $O/2_with_async.mlir 2>/dev/null
grep -cE "gpu\.(alloc|memcpy|dealloc)" $O/2_with_async.mlir | sed 's/^/gpu.alloc|memcpy|dealloc ops left WITH gpu-async-region: /' > $O/2_survivors_with_async.txt
# 3. gpu-to-llvm BEFORE the kernel is converted: the 23-vs-5 operand verifier error
mlir-opt-18 $O/async.mlir --pass-pipeline='builtin.module(lower-affine,nvvm-attach-target{chip=sm_70 features=+ptx60},gpu-to-llvm,gpu.module(convert-gpu-to-nvvm{index-bitwidth=64},reconcile-unrealized-casts),gpu-module-to-binary{format=isa})' -o /dev/null 2>&1 | head -2 | cut -c1-200 | sed "s#$HERE/##g" > $O/3_operands_before_kernel_conversion.txt
rm -f $O/2_no_async.mlir $O/2_with_async.mlir
exit 0
