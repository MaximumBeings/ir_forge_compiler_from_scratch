#!/bin/sh
# Chapter 10's sandbox probe: what GPU tooling exists here? Output: probe_out.txt
echo '$ which nvcc nvidia-smi'; which nvcc nvidia-smi; echo "(exit status $?)"
echo '$ ls /dev | grep -i nvidia'; ls /dev | grep -i nvidia; echo "(exit status $?)"
echo '$ nvptx-arch'; /usr/lib/llvm-18/bin/nvptx-arch 2>&1; echo "(exit status $?)"
echo '$ llc-18 --version | grep -iE "nvptx|amdgcn"'; llc-18 --version | grep -iE "nvptx|amdgcn"
echo '$ mlir-opt-18 --help | grep -E "convert-gpu-to-nvvm|nvvm-attach-target|gpu-module-to-binary|gpu-lower-to-nvvm-pipeline"'
mlir-opt-18 --help | grep -E -- "--(convert-gpu-to-nvvm|nvvm-attach-target|gpu-module-to-binary|gpu-lower-to-nvvm-pipeline) " | cut -c1-110
printf '%s\n' '$ mlir-opt-18 --show-dialects < /dev/null | tr "," "\n" | grep -E "gpu|nvvm|rocdl"'
mlir-opt-18 --show-dialects < /dev/null 2>&1 | tr ',' '\n' | grep -E "^(gpu|nvvm|rocdl|nvgpu)$"
