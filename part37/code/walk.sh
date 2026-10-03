#!/bin/sh
# Chapter 37: run LLVM's `opt` on the matrix product's IR with a growing list of passes, and watch what changes. For each prefix of the list prints the number of
# instructions, the number of basic blocks, and the number of lines mentioning a vector of doubles (<N x double>). `opt` needs the target (-mtriple, -mcpu) to know
# which vector instructions exist: without it the vectorizer does nothing (tried first; every row showed 0 vector lines). Output: walk_out.txt
HERE=$(cd "$(dirname "$0")" && pwd); MGC=$HERE/../../part32/code/mgc; W=$HERE/work/walk; rm -rf $W; mkdir -p $W
count() { awk '/^define/{inf=1} inf && /^  [^ ]/ && !/^  ;/{n++} inf && /^[0-9A-Za-z_.]+:/{b++} END{printf "%3d instructions, %2d blocks", n, b+1}'; }
run() {  # ll label pipeline
  out=$(opt-18 -mtriple=x86_64-unknown-linux-gnu -mcpu=native -passes="$3" -S $1 2>&1); v=$(echo "$out" | grep -c '<[0-9]* x double>')
  printf '%s, %3d lines with vector doubles   <- %s\n' "$(echo "$out" | count)" $v "$2"
}
P0="instcombine,simplifycfg"; P1="$P0,loop-simplify,lcssa,loop-rotate"; P2="$P1,loop-mssa(licm)"; P3="$P2,indvars"; P4="$P3,loop-vectorize"; P5="$P4,instcombine,simplifycfg"; P6="$P5,loop-unroll"
for order in ijk ikj; do
  MGC_KEEP=$W/$order $MGC lib $HERE/examples/02_matmul64.mg -o $W/$order -O0 --matmul-order $order >/dev/null; ll=$W/$order/02_matmul64.ll
  echo "== $order order, 64 x 64 (opt-18, target x86-64 with this machine's CPU)"
  run $ll "as emitted by mgc (no passes)" "no-op-module"
  run $ll "instcombine, simplifycfg" "function($P0)"
  run $ll "+ loop-simplify, lcssa, loop-rotate" "function($P1)"
  run $ll "+ licm (loop-invariant code motion)" "function($P2)"
  run $ll "+ indvars" "function($P3)"
  run $ll "+ loop-vectorize" "function($P4)"
  run $ll "+ instcombine, simplifycfg again" "function($P5)"
  run $ll "+ loop-unroll" "function($P6)"
  run $ll "the whole -O3 pipeline" "default<O3>"
  echo
done
echo "== what the whole -O3 pipeline made of the ijk product's setup and inner loop (the lines that matter, from opt's own output)"
opt-18 -mtriple=x86_64-unknown-linux-gnu -mcpu=native -passes='default<O3>' -S $W/ijk/02_matmul64.ll > $W/ijk_O3.ll
grep -nE "calloc|malloc|phi double|%\.promoted|fmul double|fadd double" $W/ijk_O3.ll | head -14 | cut -c1-120
printf 'in all: %d fadd, %d fmul, %d loads, %d stores, %d calloc, %d malloc\n' "$(grep -c 'fadd double' $W/ijk_O3.ll)" "$(grep -c 'fmul double' $W/ijk_O3.ll)" "$(grep -c 'load double' $W/ijk_O3.ll)" "$(grep -c 'store double' $W/ijk_O3.ll)" "$(grep -c 'call.*@calloc' $W/ijk_O3.ll)" "$(grep -c 'call.*@malloc' $W/ijk_O3.ll)"
echo
echo "== the one line with a vector of doubles that the ijk order has after loop-vectorize (before the loop-idiom pass that later turns the whole zero-fill loop into calloc)"
opt-18 -mtriple=x86_64-unknown-linux-gnu -mcpu=native -passes="function($P4)" -S $W/ijk/02_matmul64.ll | grep '<[0-9]* x double>'
