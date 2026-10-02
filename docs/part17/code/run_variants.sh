#!/bin/sh
# Lower chain.mlir (dynamic add then transpose) to affine, apply one set of Chapter 7 passes, lower to native code, and
#   (1) run the self-checking harness on eleven runtime shapes,
#   (2) run the mismatch harness, which must ABORT (Chapter 14's runtime check must survive the transform).
# Needs ../../part14/code/build.sh to have been run. Output: run_variants_out.txt
HERE=$(cd "$(dirname "$0")" && pwd); M=${MG_OPT:-$HERE/../../part14/code/build/mg-opt}; W=$HERE/work; mkdir -p $W
LOW='--lower-affine --convert-scf-to-cf --convert-arith-to-llvm --finalize-memref-to-llvm --convert-func-to-llvm --reconcile-unrealized-casts'
$M $HERE/chain.mlir --convert-mg-to-affine -o $W/chain_affine.mlir || exit 2
build() {  # name  (expects $W/name.affine.mlir)
  $M $W/$1.affine.mlir $LOW -o $W/$1.llvm.mlir 2>$W/$1.err && mlir-translate-18 --mlir-to-llvmir $W/$1.llvm.mlir -o $W/$1.ll &&
  clang-18 -c $W/$1.ll -o $W/$1.o 2>/dev/null && clang-18 $HERE/chain_harness.c $W/$1.o -o $W/$1.exe &&
  clang-18 $HERE/chain_mismatch_harness.c $W/$1.o -o $W/$1.mm
}
report() {  # name
  loops=$(grep -c "affine.for" $W/$1.affine.mlir)
  shapes=$($W/$1.exe | grep -E "^(ALL|SOME)")
  $W/$1.mm >/dev/null 2>&1; rc=$?
  case $rc in 134) abort="aborts (exit 134)";; 0) abort="DID NOT ABORT";; *) abort="exit $rc";; esac
  printf "%-16s loops=%-2s  shapes: %-16s  mismatch: %s\n" "$1" "$loops" "$shapes" "$abort"
}
run() {  # name, passes...
  name=$1; shift
  $M $W/chain_affine.mlir "$@" -o $W/$name.affine.mlir 2>$W/$name.err || { echo "$name: transform FAILED: $(head -c 200 $W/$name.err)"; return; }
  build $name || { echo "$name: build FAILED: $(head -c 300 $W/$name.err)"; return; }
  report $name
}
echo "variant          (loops = affine.for in the transformed IR; baseline has 4)"
run baseline
run fusion        --affine-loop-fusion
run tile2         --affine-loop-tile="tile-size=2"
run tile4         --affine-loop-tile="tile-size=4"
run tile16        --affine-loop-tile="tile-size=16"
run unroll_full   --affine-loop-unroll="unroll-full"
run unroll2       --affine-loop-unroll="unroll-factor=2"
run unroll4       --affine-loop-unroll="unroll-factor=4"
run tile4_unroll2 --affine-loop-tile="tile-size=4" --affine-loop-unroll="unroll-factor=2"
echo
echo "NEGATIVE CONTROL: baseline with every arith.addf rewritten to arith.subf. The harness must FAIL."
sed 's/arith.addf/arith.subf/' $W/baseline.affine.mlir > $W/control.affine.mlir
build control && { $W/control.exe | head -4 | sed 's/^/   /'; $W/control.exe | grep -E "^(ALL|SOME)" | sed 's/^/   /'; }
exit 0
