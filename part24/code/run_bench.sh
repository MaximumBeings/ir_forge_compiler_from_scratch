#!/bin/sh
# Chapter 24: Chapter 23's experiment with the new i,k,j loop order added. Output: bench_out_1.txt, bench_out_2.txt (two complete passes).
# What is timed: one call to a 64..512 square matrix product, per-call time over 7 trials (each trial repeats the call until it lasts >= 50 ms).
# Every variant's result is compared against a reference computed with an ordinary triple loop (small integers, so every sum is exact).
HERE=$(cd "$(dirname "$0")" && pwd); W=$HERE/work/bench; mkdir -p $W
MGC=$HERE/mgc; SRC=$HERE/bench/matmul.mg; H=$HERE/bench/bench.cpp
CORE=; command -v taskset >/dev/null && CORE="taskset -c 3"      # pin to one core to reduce scheduler noise
build_mg() {  # name  mgc-flags...   (MGC_CFLAGS may be set by the caller)
  name=$1; shift; mkdir -p $W/$name
  $MGC lib $SRC -o $W/$name "$@" >/dev/null
  clang++-18 -std=c++17 -O2 -DVARIANT_MG $H $W/$name/matmul.o -o $W/$name/bench
}
T32="--affine-loop-tile=tile-size=32"
build_mg mg_O2 -O2
build_mg mg_O2_ikj -O2 --matmul-order ikj
build_mg mg_O2_ikj_tile32 -O2 --matmul-order ikj --passes "$T32"
MGC_CFLAGS=-march=native build_mg mg_O3_native_tile32 -O3 --passes "$T32"
MGC_CFLAGS=-march=native build_mg mg_O3_native_ikj -O3 --matmul-order ikj
MGC_CFLAGS=-march=native build_mg mg_O3_native_ikj_tile32 -O3 --matmul-order ikj --passes "$T32"
clang++-18 -std=c++17 -O2 -DVARIANT_IJK $H -o $W/ref_ijk
clang++-18 -std=c++17 -O3 -march=native -DVARIANT_IKJ $H -o $W/ref_ikj_native
echo "machine: $(nproc) CPUs, $(grep -m1 'model name' /proc/cpuinfo | sed 's/.*: //'), $(clang++-18 --version | head -1)"
echo "pinned with: ${CORE:-nothing}   load average before: $(cut -d' ' -f1-3 /proc/loadavg)"
for v in mg_O2 mg_O2_ikj mg_O2_ikj_tile32 mg_O3_native_tile32 mg_O3_native_ikj mg_O3_native_ikj_tile32; do $CORE $W/$v/bench $v; done
$CORE $W/ref_ijk "C++ ijk loop, clang -O2"
$CORE $W/ref_ikj_native "C++ ikj loop, -O3 native"
echo "load average after: $(cut -d' ' -f1-3 /proc/loadavg)"
