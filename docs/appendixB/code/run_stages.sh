#!/bin/sh
# Appendix B: one tiny Mountain Goat program, shown after each lowering stage of mgc (the stages are real tool invocations, the same ones `mgc run` makes). Writes the files the page embeds.
cd "$(dirname "$0")"; MGC=../../part44/code/mgc; MO=../../part44/code/build/mg-opt
$MGC mlir tiny.mg                                                            > 1_mg.mlir            # the front end: mg dialect
$MO 1_mg.mlir --convert-mg-to-affine                                         > 2_affine.mlir        # mg -> affine loops over memrefs
$MO 2_affine.mlir --lower-affine --mg-scf-to-cf-reverse --mg-lower-assert-to-stderr --convert-math-to-llvm --convert-arith-to-llvm --finalize-memref-to-llvm --convert-func-to-llvm --reconcile-unrealized-casts > 3_llvm.mlir   # -> LLVM dialect
mlir-translate-18 --mlir-to-llvmir 3_llvm.mlir                                > 4_scale_add.ll       # LLVM dialect -> LLVM IR text
$MGC run tiny.mg 2>&1 | sed 's/base@ = 0x[0-9a-f]*/base@ = 0x…/'             > 5_run_out.txt
wc -l 1_mg.mlir 2_affine.mlir 3_llvm.mlir 4_scale_add.ll
# the anatomy of one operation: the same function in MLIR's pretty form and in its generic form, and what a pass (canonicalize) does to it
mlir-opt-18 add_zero.mlir                                  > 6_pretty.mlir
mlir-opt-18 add_zero.mlir --mlir-print-op-generic          > 7_generic.mlir
mlir-opt-18 add_zero.mlir --canonicalize                   > 8_canonicalized.mlir
