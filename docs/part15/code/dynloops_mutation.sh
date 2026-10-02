#!/bin/sh
# Chapter 17: do the dynamic-loop tests fail when the thing they pin changes? Each mutation edits ONE file in a COPY of the
# suite and runs only the affected test. A mutation that changes the file's line count is rejected (a substitution never should).
HERE=$(cd "$(dirname "$0")" && pwd)
export MG_OPT=${MG_OPT:-$HERE/../../part14/code/build/mg-opt}
export DECODE_PTX=$(cd "$HERE/../../part10/code" && pwd)/decode_ptx.py
n=0
mut() {  # description | file under test/ | sed expression | test to run
  n=$((n+1)); W=$HERE/work/dm-$n; rm -rf "$W"; mkdir -p "$W"; cp -r "$HERE/test" "$W/test"
  sed -i "$3" "$W/test/$2"
  if cmp -s "$HERE/test/$2" "$W/test/$2"; then echo "MUTATION $n NOT APPLIED ($1)"; return; fi
  if [ "$(wc -l < "$HERE/test/$2")" != "$(wc -l < "$W/test/$2")" ]; then echo "MUTATION $n MALFORMED ($1): line count changed"; return; fi
  out=$(MG_TEST_TMP="$W/out" lit "$W/test/$4" 2>&1 | grep -E "^(PASS|FAIL)" | sed 's/IR Forge \/ Mountain Goat :: //;s/ ([0-9]* of [0-9]*)//')
  echo "MUTATION $n: $1"; echo "   $out"
}
mut "tile size 4 -> 2 in the structure test's recipe"          dynamic-loops/tiling-structure.mlir        '/RUN:/s/tile-size=4/tile-size=2/'  dynamic-loops/tiling-structure.mlir
mut "unroll factor 2 -> 4 in the epilogue test's recipe"        dynamic-loops/unroll-epilogue.mlir         '/RUN:/s/unroll-factor=2/unroll-factor=4/'  dynamic-loops/unroll-epilogue.mlir
mut "fusion-declines run on the STATIC chain (fusion fires)"    dynamic-loops/fusion-declines.mlir         '/RUN:/s#%inputs/chain.mlir#%inputs/static_chain.mlir#'  dynamic-loops/fusion-declines.mlir
mut "self-checking harness computes a-b instead of a+b"         Inputs/chain_harness.c                     's/double want = a\[i \* cols + j\] + b\[i \* cols + j\];/double want = a[i * cols + j] - b[i * cols + j];/'  dynamic-loops/tiling-runs.mlir
mut "partial-static unroll test fed the fully dynamic chain"    dynamic-loops/unroll-full-needs-constant-trip-count.mlir  '/check-prefix=PART/s#%inputs/chain2.mlir#%inputs/chain.mlir#'  dynamic-loops/unroll-full-needs-constant-trip-count.mlir
mut "mismatch harness made to MATCH (no abort expected)"        Inputs/chain_mismatch_harness.c            's/b\[2\] = {10,20}/b[6] = {10,20,30,40,50,60}/; s/b,b,0,1,2,2,1/b,b,0,2,3,3,1/'  dynamic-loops/runtime-check-survives-transforms.mlir
mut "rule test: the DECLINES run for A fed the static control C"    dynamic-loops/fusion-needs-constant-trip-counts.mlir  '/RUN:.*exp_A.mlir/s#exp_A.mlir#exp_C.mlir#'  dynamic-loops/fusion-needs-constant-trip-counts.mlir
mut "rule test: the FUSES run for B fed the dynamic-bound program A"  dynamic-loops/fusion-needs-constant-trip-counts.mlir  '/RUN:.*exp_B.mlir/s#exp_B.mlir#exp_A.mlir#'  dynamic-loops/fusion-needs-constant-trip-counts.mlir
mut "rule test: the DECLINES run for G fed the static control C"    dynamic-loops/fusion-needs-constant-trip-counts.mlir  '/RUN:.*exp_G.mlir/s#exp_G.mlir#exp_C.mlir#'  dynamic-loops/fusion-needs-constant-trip-counts.mlir
mut "bug-pin test: the dynamic run fed the STATIC chain (no error expected)"  dynamic-loops/fusion-after-tiling.mlir  '/RUN: %mg-opt %inputs\/chain.mlir/s#chain.mlir#static_chain.mlir#'  dynamic-loops/fusion-after-tiling.mlir
mut "bug-pin test: static run for tile 1 given tile size 2 instead"           dynamic-loops/fusion-after-tiling.mlir  '/RUN:.*static_chain.*tile-size=1/s#tile-size=1#tile-size=2#'  dynamic-loops/fusion-after-tiling.mlir
