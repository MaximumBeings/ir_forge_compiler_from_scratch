#!/bin/sh
# Chapter 16: do the loop and GPU tests fail when the recipe or runtime they pin is changed?
# Each mutation edits ONE file in a COPY of the suite, then runs only the affected test(s) there.
HERE=$(cd "$(dirname "$0")" && pwd)
export MG_OPT=${MG_OPT:-$HERE/../../part14/code/build/mg-opt}
export DECODE_PTX=$(cd "$HERE/../../part10/code" && pwd)/decode_ptx.py
n=0
mut() {  # description | file under test/ | sed expression | test(s) to run
  n=$((n+1)); W=$HERE/work/rm-$n; rm -rf "$W"; mkdir -p "$W"; cp -r "$HERE/test" "$W/test"
  sed -i "$3" "$W/test/$2"
  if cmp -s "$HERE/test/$2" "$W/test/$2"; then echo "MUTATION $n NOT APPLIED ($1)"; return; fi
  # a substitution edits lines in place; if the line count changed, the sed expression did something else
  if [ "$(wc -l < "$HERE/test/$2")" != "$(wc -l < "$W/test/$2")" ]; then echo "MUTATION $n MALFORMED ($1): line count changed"; return; fi
  out=$(MG_TEST_TMP="$W/out" lit "$W/test/$4" 2>&1 | grep -E "^(PASS|FAIL)" | sed 's/IR Forge \/ Mountain Goat :: //;s/ ([0-9]* of [0-9]*)//')
  echo "MUTATION $n: $1"; echo "   $out"
}
mut "index-bitwidth=64 -> 32"                       gpu/ptx-default.mlir                '/index-bitwidth=64/s/64/32/' gpu/ptx-default.mlir
mut "target chip sm_70 -> sm_80"                     gpu/ptx-default.mlir                's/chip=sm_70/chip=sm_80/' gpu/ptx-default.mlir
mut "bare-pointer option dropped (5 -> 23 params)"   gpu/ptx-bare-pointers.mlir          's/ kernel-bare-ptr-calling-convention=1//' gpu/ptx-bare-pointers.mlir
mut "bare-pointer option added to the host test"     gpu/host-runtime-calls.mlir         '/RUN: %mlir-opt %t.async.mlir/s/cubin-format=isa"/cubin-format=isa kernel-bare-ptr-calling-convention=1"/' gpu/host-runtime-calls.mlir
mut "gpu-map-parallel-loops left out of the recipe"  gpu/kernel-outlining.mlir           's#%to-gpu#--pass-pipeline="builtin.module(func.func(affine-parallelize,lower-affine,convert-parallel-loops-to-gpu),gpu-kernel-outlining)"#' gpu/kernel-outlining.mlir
mut "tile-size 1 -> 2"                               loops/tiling.mlir                   's/tile-size=1/tile-size=2/' loops/tiling.mlir
mut "second full-unroll pass removed"                loops/unroll-full.mlir              's/ --affine-loop-unroll="unroll-full" --canonicalize/ --canonicalize/' loops/unroll-full.mlir
mut "stub runtime's kernel computes a-b, not a+b"    Inputs/stub_gpu_runtime.c           's/c\[i\] = a\[i\] + b\[i\];/c[i] = a[i] - b[i];/' execution/gpu-host-with-stub-runtime.mlir
