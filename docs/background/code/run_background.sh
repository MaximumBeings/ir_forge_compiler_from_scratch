#!/bin/sh
# Every command on the Background page, run for real. Output: background_out.txt
cd "$(dirname "$0")"
sec() { echo; echo "################ $*"; }
sec "versions"; clang-18 --version | head -1; mlir-opt-18 --version | grep -i "LLVM version"
sec "1. clang -S -emit-llvm -O0 sum.c      (C to LLVM IR, no optimization)"; clang-18 -S -emit-llvm -O0 -Xclang -disable-O0-optnone sum.c -o - | grep -v '^;\|^source_filename\|^target\|^$\|^!\|^attributes\|^#\|^declare'
sec "2. clang -S -emit-llvm -O0 loop.c     (a loop: several basic blocks, memory for every variable)"; clang-18 -S -emit-llvm -O0 -Xclang -disable-O0-optnone loop.c -o - | grep -v '^;\|^source_filename\|^target\|^$\|^!\|^attributes\|^#\|^declare'
sec "3. the same loop after LLVM's optimizer (clang -O1): registers and a phi, no memory"; clang-18 -S -emit-llvm -O1 loop.c -o - | grep -v '^;\|^source_filename\|^target\|^$\|^!\|^attributes\|^#\|^declare\|llvm.loop\|^\s*$'
sec "4. LLVM IR written by hand, compiled with clang and run"; cat handwritten.ll | sed 's/^/  | /'; clang-18 main_max.c handwritten.ll -o /tmp/bg_max 2>&1 | grep -v warning; /tmp/bg_max
sec "5. mlir-opt-18 add.mlir               (parse, verify, print back)"; mlir-opt-18 add.mlir
sec "6. the same, in MLIR's generic form: every operation is  name(operands) attributes : type"; mlir-opt-18 add.mlir --mlir-print-op-generic
sec "7. mlir-opt-18 fold.mlir --canonicalize --cse     (constant folding and common-subexpression elimination)"; mlir-opt-18 fold.mlir --canonicalize --cse
sec "8. sum_loop.mlir as written"; mlir-opt-18 sum_loop.mlir
sec "9. one lowering step:  --convert-scf-to-cf     (the structured loop becomes blocks and branches)"; mlir-opt-18 sum_loop.mlir --convert-scf-to-cf
sec "10. all the way down:  --convert-scf-to-cf --convert-arith-to-llvm --convert-func-to-llvm --reconcile-unrealized-casts"; mlir-opt-18 sum_loop.mlir --convert-scf-to-cf --convert-arith-to-llvm --convert-func-to-llvm --reconcile-unrealized-casts
sec "11. mlir-translate-18 --mlir-to-llvmir   (the 'llvm' dialect text becomes real LLVM IR)"
mlir-opt-18 sum_loop.mlir --convert-scf-to-cf --convert-arith-to-llvm --convert-func-to-llvm --reconcile-unrealized-casts -o /tmp/bg_sum.llvm.mlir
mlir-translate-18 --mlir-to-llvmir /tmp/bg_sum.llvm.mlir -o /tmp/bg_sum.ll; grep -v '^;\|^source_filename\|^target\|^$\|^!\|^attributes\|^#' /tmp/bg_sum.ll
sec "12. clang-18 on that LLVM IR, linked with a C main, run"; clang-18 main_sum.c /tmp/bg_sum.ll -o /tmp/bg_sum 2>&1 | grep -v warning; /tmp/bg_sum
