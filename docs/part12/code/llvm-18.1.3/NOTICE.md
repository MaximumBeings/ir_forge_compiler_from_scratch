# Provenance of the files in this directory

These three files are **unmodified copies** from the `llvm/llvm-project` repository at tag `llvmorg-18.1.3`
(commit `c13b748`), read for Chapter 12:

| File here | Path in llvm-project |
|---|---|
| `GPUToNVVMPipeline.cpp` | `mlir/lib/Dialect/GPU/Pipelines/GPUToNVVMPipeline.cpp` |
| `SparseTensorPipelines.cpp` | `mlir/lib/Dialect/SparseTensor/Pipelines/SparseTensorPipelines.cpp` |
| `GPUToLLVMConversion.cpp` | `mlir/lib/Conversion/GPUCommon/GPUToLLVMConversion.cpp` |

They were obtained with `git clone --depth 1 --branch llvmorg-18.1.3 --filter=blob:none --sparse` followed by
`git sparse-checkout set` on the directories above. They are licensed under the Apache License v2.0 with LLVM
Exceptions (see the header of each file and https://llvm.org/LICENSE.txt); the license headers are intact.
They are included so that Chapter 12's page can show the exact lines it argues from. Nothing here is this book's code.
