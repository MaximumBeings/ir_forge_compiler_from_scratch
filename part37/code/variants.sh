#!/bin/sh
# Chapter 37: which of two reasons keeps the default (i,j,k) matrix product slow: the floating-point REDUCTION that LLVM will not reorder (so the inner loop is not
# vectorized), or the strided walk down a column of b? Builds the Chapter 24 benchmark's matrix product (dynamic sizes) in both loop orders and, for each, with and
# without permission to reorder the additions; and the ikj product also with permission to fuse each multiply and add into one instruction (the `contract` flag). Permission is given IN THE IR (the `reassoc` flag on every fadd), because the clang option -ffast-math does nothing to
# a .ll file (the first version of this experiment used it, and the assembly came out byte-for-byte identical; see check_llvm.sh).
# Method: Chapter 24's bench.cpp (its result check against a reference is part of every line), pinned to one core, THREE passes. Output: variants_out.txt
HERE=$(cd "$(dirname "$0")" && pwd); W=$HERE/work/variants; mkdir -p $W
MGC=$HERE/../../part32/code/mgc; SRC=$HERE/../../part24/code/bench/matmul.mg; H=$HERE/../../part24/code/bench/bench.cpp
export MG_OPT=${MG_OPT:-$(ls $HERE/../../part38/code/build/mg-opt 2>/dev/null || echo $HERE/../../part32/code/build/mg-opt)}
CORE=; command -v taskset >/dev/null && CORE="taskset -c 3"
build() {  # name  order  flag(0 none | 1 reassoc on fadd | 2 contract on fmul and fadd)
  name=$1; order=$2; re=$3; mkdir -p $W/$name
  MGC_KEEP=$W/$name $MGC lib $SRC -o $W/$name -O3 --matmul-order $order >/dev/null
  [ $re = 1 ] && sed -i 's/fadd double/fadd reassoc double/' $W/$name/matmul.ll
  [ $re = 2 ] && sed -i 's/fadd double/fadd contract double/; s/fmul double/fmul contract double/' $W/$name/matmul.ll
  clang-18 -O3 -march=native -c $W/$name/matmul.ll -o $W/$name/matmul.o 2>/dev/null
  clang++-18 -std=c++17 -O2 -DVARIANT_MG $H $W/$name/matmul.o -o $W/$name/bench
}
build ijk ijk 0; build ijk_reassoc ijk 1; build ikj ikj 0; build ikj_reassoc ikj 1; build ikj_contract ikj 2
echo "machine: $(nproc) CPUs, $(grep -m1 'model name' /proc/cpuinfo | sed 's/.*: //'), $(clang++-18 --version | head -1)"
echo "pinned with: ${CORE:-nothing}   load average before: $(cut -d' ' -f1-3 /proc/loadavg)"
for pass in 1 2 3; do
  echo "--- pass $pass"
  for v in ijk ijk_reassoc ikj ikj_reassoc ikj_contract; do $CORE $W/$v/bench "$v" | grep "dynamic sizes" | grep -E "N=(256|512)"; done
done
echo "load average after: $(cut -d' ' -f1-3 /proc/loadavg)"
