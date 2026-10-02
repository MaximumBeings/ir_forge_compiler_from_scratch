#!/bin/sh
# Chapter 24: do the compiled matrix products use vector (packed/FMA) instructions? Counts vfmadd/vmulpd/vaddpd in each function
# of an -O3 -march=native build, for each loop order, tiled and untiled. Output: inspect_asm_out.txt
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
T32="--affine-loop-tile=tile-size=32"
count ijk "ijk, untiled" -O3
count ijk_t "ijk, tiled (32)" -O3 --passes "$T32"
count ikj "ikj, untiled" -O3 --matmul-order ikj
count ikj_t "ikj, tiled (32)" -O3 --matmul-order ikj --passes "$T32"
