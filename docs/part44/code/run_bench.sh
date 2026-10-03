#!/bin/sh
# Chapter 44: the matrix product with and without --fast-math (reassoc,contract), ijk and ikj loop orders, clang -O2 and -O3 -march=native, pinned to one core, 7 trials per cell.
# The first build of each (order, clang) pair is WITHOUT flags and writes its results to a file; the build with flags is compared to that file bit by bit. Output: bench_out.txt   (about 3 minutes)
HERE=$(cd "$(dirname "$0")" && pwd); W=$HERE/work/bench; rm -rf $W; mkdir -p $W; MGC=$HERE/mgc; CORE=; command -v taskset >/dev/null && CORE="taskset -c 3"
echo "machine: $(nproc) CPUs, $(grep -m1 'model name' /proc/cpuinfo | sed 's/.*: //'), $(clang++-18 --version | head -1)"; echo "pinned with: ${CORE:-nothing}   load average before: $(cut -d' ' -f1-3 /proc/loadavg)"
for order in ijk ikj; do for lvl in "-O2" "-O3 -march=native"; do
  tag=$order-$(echo $lvl | sed 's/ -march=native/-native/; s/^-//'); for fm in plain fast; do
    fl=; [ $fm = fast ] && fl=--fast-math; d=$W/$tag-$fm; mkdir -p $d
    MGC_CFLAGS="$(echo $lvl | grep -o -- '-march=native')" $MGC lib $HERE/bench/matmul.mg -o $d $(echo $lvl | grep -o -- '-O[0-9]') --no-outline --matmul-order $order $fl >/dev/null
    clang++-18 -std=c++17 -O2 $HERE/bench/bench.cpp $d/matmul.o -o $d/bench
  done
  $CORE $W/$tag-plain/bench "$order, $lvl, plain" $W/$tag.ref; $CORE $W/$tag-fast/bench "$order, $lvl, --fast-math" $W/$tag.ref
done; done
echo "load average after: $(cut -d' ' -f1-3 /proc/loadavg)"
