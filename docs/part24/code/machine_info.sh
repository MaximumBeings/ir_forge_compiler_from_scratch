#!/bin/sh
# What machine the Chapter 23 numbers come from. Output: machine_info_out.txt
echo "CPU:      $(grep -m1 'model name' /proc/cpuinfo | sed 's/.*: //')"
lscpu | grep -E "^(CPU\(s\)|Thread|Core|Socket|L1d|L2|L3)" | sed 's/  */ /g'
echo "vector extensions available: $(grep -o -w 'sse4_2\|avx\|avx2\|fma\|avx512f' /proc/cpuinfo | sort -u | tr '\n' ' ')"
echo "memory:   $(free -m | awk '/Mem:/ {print $2 " MiB"}')"
echo "kernel:   $(uname -sr)"
echo "compiler: $(clang++-18 --version | head -1)"
echo "mlir:     $(mlir-opt-18 --version | grep -m1 'LLVM version')"
echo "This is a shared cloud virtual machine, not a quiet benchmarking box; see the chapter for what that means for the numbers."
