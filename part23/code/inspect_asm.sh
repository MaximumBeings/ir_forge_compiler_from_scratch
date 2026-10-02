#!/bin/sh
# Look at the machine code behind the benchmark: do the compiled matrix products use vector (packed/FMA) instructions?
# Counts vfmadd/vmulpd/vaddpd instructions in each function of an -O3 -march=native build. Output: inspect_asm_out.txt
HERE=$(cd "$(dirname "$0")" && pwd); W=$HERE/work/asm; mkdir -p $W
count() {  # name label mgc-flags...
  name=$1; label=$2; shift 2; mkdir -p $W/$name
  MGC_KEEP=$W/$name MGC_CFLAGS=-march=native $HERE/mgc lib $HERE/bench/matmul.mg -o $W/$name "$@" >/dev/null
  clang-18 -O3 -march=native -S $W/$name/matmul.ll -o $W/$name/matmul.s 2>/dev/null
  for f in mm_dyn mm_256; do
    n=$(awk "/^$f:/,/\\.cfi_endproc/" $W/$name/matmul.s | grep -c 'vfmadd\|vmulpd\|vaddpd')
    echo "$label, $f: $n vector/FMA instructions"
  done
}
count untiled "untiled, -O3 -march=native" -O3
count tiled32 "tiled (32), -O3 -march=native" -O3 --passes "--affine-loop-tile=tile-size=32"
