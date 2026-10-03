// Chapter 37: the programs the chapter reads are ordinary Mountain Goat programs: each compiles to the expected mg-dialect operation, and every one-operation program in
// ops/ compiles (the chapter then asks what LLVM makes of each).
// RUN: %mgc32 mlir %ex37/01_add2x2.mg | %FileCheck %s --check-prefix=ADD
// RUN: %mgc32 mlir %ex37/02_matmul64.mg | %FileCheck %s --check-prefix=MM
// RUN: %mgc32 mlir %ex37/03_matmul_dynamic.mg | %FileCheck %s --check-prefix=DYN
// RUN: sh -c 'n=0; for f in %ex37/../ops/*.mg; do %mgc32 mlir $f > /dev/null || exit 1; n=$((n+1)); done; test $n -eq 14'
// ADD: mg.add %a, %b : tensor<2x2xf64>, tensor<2x2xf64> -> tensor<2x2xf64>
// MM: mg.matmul %a, %b : tensor<64x64xf64>, tensor<64x64xf64> -> tensor<64x64xf64>
// DYN: mg.matmul %a, %b : tensor<?x?xf64>, tensor<?x?xf64> -> tensor<?x?xf64>
