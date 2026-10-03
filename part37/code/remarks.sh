#!/bin/sh
# Chapter 37: ask LLVM's loop vectorizer what it decided about the matrix product, and why. clang -Rpass / -Rpass-missed / -Rpass-analysis print the decision for every loop.
# Three experiments: (1) the two loop orders, with and without -march=native; (2) give permission to reorder the additions IN THE IR (the `reassoc` flag on each fadd);
# (3) the same permission asked for with clang's -ffast-math option, which does nothing to a .ll file (shown by comparing the two assembly files byte for byte).
# Output: remarks_out.txt
HERE=$(cd "$(dirname "$0")" && pwd); MGC=$HERE/../../part32/code/mgc; W=$HERE/work/remarks; rm -rf $W; mkdir -p $W
R="-Rpass=loop-vectorize -Rpass-missed=loop-vectorize -Rpass-analysis=loop-vectorize"
remarks() { clang-18 -O3 $2 $R -c $1 -o /dev/null 2>&1 | grep '^remark' | sed 's/^remark: <unknown>:0:0: //; s/ \[-Rpass.*//' | cut -c1-300; }
for order in ijk ikj; do MGC_KEEP=$W/$order $MGC lib $HERE/examples/02_matmul64.mg -o $W/$order -O0 --matmul-order $order >/dev/null; done
for order in ijk ikj; do for fl in "" "-march=native"; do echo "== $order, clang -O3 $fl"; remarks $W/$order/02_matmul64.ll "$fl"; done; done
echo
echo "== (2) ijk with the reassoc flag on every fadd in the IR (sed 's/fadd double/fadd reassoc double/'), clang -O3 -march=native"
sed 's/fadd double/fadd reassoc double/' $W/ijk/02_matmul64.ll > $W/ijk_reassoc.ll; echo "fadd instructions changed: $(grep -c 'fadd reassoc double' $W/ijk_reassoc.ll)"
remarks $W/ijk_reassoc.ll "-march=native"
echo
echo "== (3) ijk with clang's -ffast-math option on the unchanged .ll"
remarks $W/ijk/02_matmul64.ll "-march=native -ffast-math"
clang-18 -O3 -march=native -S $W/ijk/02_matmul64.ll -o $W/plain.s 2>/dev/null; clang-18 -O3 -march=native -ffast-math -S $W/ijk/02_matmul64.ll -o $W/fast.s 2>/dev/null
cmp -s $W/plain.s $W/fast.s && echo "assembly with and without -ffast-math: byte for byte identical" || echo "assembly with and without -ffast-math: DIFFERENT"
echo
echo "== the same sizes unknown until run time (examples/03_matmul_dynamic.mg), ijk and ikj, clang -O3 -march=native"
for order in ijk ikj; do MGC_KEEP=$W/d_$order $MGC lib $HERE/examples/03_matmul_dynamic.mg -o $W/d_$order -O0 --matmul-order $order >/dev/null; echo "-- $order"; remarks $W/d_$order/03_matmul_dynamic.ll "-march=native"; done
