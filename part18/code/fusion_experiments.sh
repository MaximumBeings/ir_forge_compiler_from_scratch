#!/bin/sh
# Chapter 18: which loop-bound property makes --affine-loop-fusion decline? Hand-written affine programs, one property varied each.
# All are an add nest feeding a transpose nest through an intermediate buffer; fusion should merge them (4 loops -> 2) when it can.
# Needs ../../part14/code/build.sh. Output: fusion_experiments_out.txt
HERE=$(cd "$(dirname "$0")" && pwd); M=${MG_OPT:-$HERE/../../part14/code/build/mg-opt}; W=$HERE/work; mkdir -p $W
nth() {  # file, pattern, replacement, n: replace the n-th occurrence of pattern in file
  python3 - "$1" "$2" "$3" "$4" <<'P'
import sys,re
f,pat,rep,n=sys.argv[1],sys.argv[2],sys.argv[3],int(sys.argv[4]); s=open(f).read(); k=0
def r(m):
    global k; k+=1; return rep if k==n else m.group(0)
open(f,'w').write(re.sub(pat,r,s))
P
}
# variants of the fully static control C that make exactly ONE loop's bound dynamic (a function-argument symbol %n)
for v in E F G; do sed 's/@C(%a: memref<4x6xf64>, %b: memref<4x6xf64>)/@C(%a: memref<4x6xf64>, %b: memref<4x6xf64>, %n: index)/' $HERE/exp_C.mlir > $W/exp_$v.mlir; done
nth $W/exp_E.mlir 'affine.for %i = 0 to 4' 'affine.for %i = 0 to %n' 1     # producer nest, OUTER loop dynamic
nth $W/exp_F.mlir 'affine.for %j = 0 to 6' 'affine.for %j = 0 to %n' 1     # producer nest, INNER loop dynamic
nth $W/exp_G.mlir 'affine.for %i = 0 to 6' 'affine.for %i = 0 to %n' 1     # CONSUMER nest, outer loop dynamic
cp $W/exp_E.mlir $HERE/exp_E.mlir; cp $W/exp_F.mlir $HERE/exp_F.mlir; cp $W/exp_G.mlir $HERE/exp_G.mlir
printf "%-4s %-64s %-7s %s\n" exp "what is dynamic" "before" "after fusion"
row() { f=$HERE/exp_$1.mlir; printf "%-4s %-64s %-7s %s\n" "$1" "$2" "$(grep -c affine.for $f)" "$($M $f --affine-loop-fusion | grep -c affine.for)"; }
row C "nothing (static bounds, static buffers) - control"
row A "BOTH nests' bounds (function-argument symbols); buffers static"
row B "the BUFFERS (memref<?x?xf64>); loop bounds constant"
row E "one loop: producer, outer"
row F "one loop: producer, inner"
row G "one loop: consumer, outer"
echo
echo "WORKAROUND ATTEMPT: tile first (constant tile size), then fuse. Static controls first."
for ts in 1 2; do
  $M $HERE/../../part17/code/static_chain.mlir --convert-mg-to-affine | $M --affine-loop-tile="tile-size=$ts" -o $W/I_t$ts.mlir
  if $M $W/I_t$ts.mlir --affine-loop-fusion -o $W/I_f$ts.mlir 2>$W/I_f$ts.err; then r="verifies, $(grep -c affine.for $W/I_f$ts.mlir) loops"; else r="VERIFIER ERROR: $(head -1 $W/I_f$ts.err | sed 's/^[^ ]* //')"; fi
  printf "I%s   STATIC 4x6 chain, tiled by %s (%s loops) then fused: %s\n" $ts $ts "$(grep -c affine.for $W/I_t$ts.mlir)" "$r"
done
$M $HERE/../../part17/code/chain.mlir --convert-mg-to-affine -o $W/H_affine.mlir
$M $W/H_affine.mlir --affine-loop-tile="tile-size=4" -o $W/H_tiled.mlir
if $M $W/H_tiled.mlir --affine-loop-fusion -o $W/H_fused.mlir 2>$W/H_fused.err; then r="verifies, $(grep -c affine.for $W/H_fused.mlir) loops"; else r="VERIFIER ERROR: $(head -1 $W/H_fused.err | sed 's/^[^ ]* //')"; fi
printf "H    DYNAMIC chain, tiled by 4 (%s loops) then fused: %s\n" "$(grep -c affine.for $W/H_tiled.mlir)" "$r"
echo
echo "What the fusion pass did to the tiled dynamic nest (verification off, generic form), first loop-header lines that differ:"
$M $W/H_tiled.mlir -mlir-print-op-generic -o $W/H_tiled_generic.mlir
$M $W/H_tiled.mlir --affine-loop-fusion --verify-each=0 -mlir-print-op-generic -o $W/H_fused_generic.mlir 2>/dev/null
diff $W/H_tiled_generic.mlir $W/H_fused_generic.mlir | grep -E '^[<>].*"affine.for"' | sed -E 's/<\{lowerBoundMap = #map1, //; s/\}> \(\{$//' | cut -c1-150
for v in E F G; do echo "### exp_$v vs the static control exp_C"; diff $HERE/exp_C.mlir $HERE/exp_$v.mlir; echo; done > $HERE/exp_variants_diff.txt
