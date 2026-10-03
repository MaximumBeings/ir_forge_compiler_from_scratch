#!/bin/sh
# Appendix C: one small C function, shown as LLVM IR (-O0 and -O1) and as x86-64 assembly (-O1), all produced by clang-18. Vectorizing and unrolling are turned off so the loop is the plain one-element-per-iteration loop.
cd "$(dirname "$0")"; F="-fno-vectorize -fno-unroll-loops -fno-slp-vectorize"
clang-18 -S -emit-llvm -O0 -Xclang -disable-O0-optnone scale.c -o 1_scale_O0.ll
clang-18 -S -emit-llvm -O1 $F scale.c -o 2_scale_O1.ll
clang-18 -S -O1 $F -fno-asynchronous-unwind-tables -masm=att scale.c -o 3_scale_O1.s
clang-18 -S -O1 $F -fno-asynchronous-unwind-tables -masm=intel scale.c -o 4_scale_O1_intel.s
# the pages embed these trimmed copies: the function only (no module metadata, no unwind tables, no directives)
grep -v '^;\|^$\|^!\|^attributes\|^source_filename\|^target' 1_scale_O0.ll | sed '/^define/,$!d'      > 5_O0_body.ll
grep -v '^;\|^$\|^!\|^attributes\|^source_filename\|^target' 2_scale_O1.ll | sed '/^define/,$!d'           > 6_O1_body.ll
grep -v '^\s*\.\(file\|text\|globl\|p2align\|type\|size\|section\|ident\|cfi\|addrsig\)\|^\.Lfunc_end\|End function' 3_scale_O1.s  > 7_O1_att.s
grep -v '^\s*\.\(file\|text\|globl\|p2align\|type\|size\|section\|ident\|cfi\|addrsig\|intel_syntax\)\|^\.Lfunc_end\|End function' 4_scale_O1_intel.s > 8_O1_intel.s
