#!/bin/sh
# Chapter 44: what mgc --fast-math puts in the IR, and what LLVM's vectorizer then decides, for the 64 x 64 matrix product in both loop orders. Output: ir_and_remarks_out.txt
CPU=${CPU:-sapphirerapids}   # pinned, as in Chapter 37, so the output does not depend on the machine that runs it
HERE=$(cd "$(dirname "$0")" && pwd); MGC=$HERE/mgc; W=$HERE/work/remarks; rm -rf $W; mkdir -p $W
R="-Rpass=loop-vectorize -Rpass-missed=loop-vectorize -Rpass-analysis=loop-vectorize"
remarks() { clang-18 -O3 $2 $R -c $1 -o /dev/null 2>&1 | grep '^remark' | sed 's/^remark: <unknown>:0:0: //; s/ \[-Rpass.*//' | cut -c1-200 | sort | uniq -c | sort -rn; }
for order in ijk ikj; do for fm in plain fast; do
  fl=; [ $fm = fast ] && fl=--fast-math; mkdir -p $W/$order-$fm; MGC_KEEP=$W/$order-$fm $MGC lib $HERE/examples/02_matmul64.mg -o $W/$order-$fm -O0 --no-outline --matmul-order $order $fl >/dev/null
done; done
echo "== the floating-point instructions in the LLVM IR of the ijk product (llvm.mlir -> .ll), without and with --fast-math"
for fm in plain fast; do echo "-- $fm: $(grep -c 'fmul' $W/ijk-$fm/02_matmul64.ll) fmul, $(grep -c 'fadd' $W/ijk-$fm/02_matmul64.ll) fadd"; grep -E 'fmul|fadd' $W/ijk-$fm/02_matmul64.ll | head -2 | sed 's/^ */   /'; done
for order in ijk ikj; do for fm in plain fast; do echo; echo "== $order, $fm: clang -O3 -march=$CPU: what the loop vectorizer says (count, remark)"; remarks $W/$order-$fm/02_matmul64.ll "-march=$CPU"; done; done
echo; echo "== the same ijk product, sizes unknown until run time (03_matmul_dynamic.mg)"
for fm in plain fast; do fl=; [ $fm = fast ] && fl=--fast-math; mkdir -p $W/d-$fm; MGC_KEEP=$W/d-$fm $MGC lib $HERE/examples/03_matmul_dynamic.mg -o $W/d-$fm -O0 --no-outline $fl >/dev/null; echo "-- $fm"; remarks $W/d-$fm/03_matmul_dynamic.ll "-march=$CPU"; done
