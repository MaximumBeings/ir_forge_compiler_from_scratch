#!/bin/sh
# Chapter 42: the wall-clock time of every stage of `mgc build` for one program, with mgc's own stage commands, so that it is visible WHERE the compile time of a huge program goes.
# usage: stage_times.sh prog.mg [mgc flags: --outline --reverse-loops]       (the executable is run at the end and its seconds are printed)
HERE=$(cd "$(dirname "$0")" && pwd); P=$1; shift
SCF=--convert-scf-to-cf; OUTLINE=
for f in "$@"; do case $f in --outline) OUTLINE=--mg-outline-loops;; --reverse-loops) SCF=--mg-scf-to-cf-reverse;; esac; done
MG_OPT=$HERE/build/mg-opt; W=$(mktemp -d); b=prog
t() { s=$(date +%s.%N); "$@"; e=$(date +%s.%N); }
now() { date +%s.%N; }
a=$(now); python3 $HERE/mgfront.py $P > $W/$b.mlir; b1=$(now)
$MG_OPT $W/$b.mlir --convert-mg-to-affine $OUTLINE -o $W/$b.affine.mlir; b2=$(now)
$MG_OPT $W/$b.affine.mlir --lower-affine $SCF --mg-lower-assert-to-stderr --convert-math-to-llvm --convert-arith-to-llvm --finalize-memref-to-llvm --convert-func-to-llvm --reconcile-unrealized-casts -o $W/$b.llvm.mlir; b3=$(now)
mlir-translate-18 --mlir-to-llvmir $W/$b.llvm.mlir -o $W/$b.ll; b4=$(now)
clang-18 $W/$b.ll -o $W/$b.exe -L/usr/lib/llvm-18/lib -lmlir_runner_utils -lm -Wl,-rpath,/usr/lib/llvm-18/lib 2>/dev/null; b5=$(now)
$W/$b.exe > $W/out.txt; b6=$(now)
awk -v a=$a -v b1=$b1 -v b2=$b2 -v b3=$b3 -v b4=$b4 -v b5=$b5 -v b6=$b6 'BEGIN{printf "front end %.1f s | mg->affine%s %.1f s | lower (lower-affine, scf->cf, LLVM dialect) %.1f s | mlir-translate %.1f s | clang -O0 %.1f s | run %.1f s | total compile %.1f s\n", b1-a, "(+outline)", b2-b1, b3-b2, b4-b3, b5-b4, b6-b5, b5-a}'
sed -E 's/base@ = 0x(…|[0-9a-f]+)/base@ = 0x/' $W/out.txt | sed '/^$/d' > $W/norm.txt
echo "output: $(wc -l < $W/norm.txt) lines, md5 of the output with addresses and blank lines removed: $(md5sum < $W/norm.txt | cut -c1-12)"
rm -rf $W
