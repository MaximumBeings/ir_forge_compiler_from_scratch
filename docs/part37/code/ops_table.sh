#!/bin/sh
# Chapter 37: for each Mountain Goat operation on 64 x 64 matrices (ops/*.mg), compile with clang -O3 -march=native and count, in the assembly, the PACKED floating-point
# arithmetic instructions (vaddpd, vmulpd, vmaxpd, vsqrtpd, vcmppd ... operate on 4 doubles at once), the SCALAR ones (vaddsd ... one double), the gather instructions,
# and the library calls. This is a count of instructions, not a timing: it says whether the compiler vectorized, not whether that was faster. Output: ops_table_out.txt
HERE=$(cd "$(dirname "$0")" && pwd); MGC=$HERE/../../part32/code/mgc; W=$HERE/work/ops; rm -rf $W; mkdir -p $W
printf '%-10s %7s %7s %7s  %s\n' operation packed scalar gather "library calls"
for f in add hadamard scale relu sqrt ge bcast_add transpose col_sum row_sum row_mean row_max exp log; do
  MGC_KEEP=$W/$f $MGC lib $HERE/ops/$f.mg -o $W/$f >/dev/null; clang-18 -O3 -march=native -S $W/$f/$f.ll -o $W/$f/$f.s 2>/dev/null
  p=$(grep -cE '\bv(add|mul|sub|div|max|min|sqrt|cmp)[a-z]*pd\b' $W/$f/$f.s); s=$(grep -cE '\bv(add|mul|sub|div|max|min|sqrt|cmp)[a-z]*sd\b' $W/$f/$f.s)
  g=$(grep -cE '\bvgather' $W/$f/$f.s); c=$(grep -E '^\s+(callq|jmp)\s' $W/$f/$f.s | sed 's/.*\s//; s/@PLT//' | grep -vE '^(malloc|calloc|free)$|^\.' | sort -u | tr '\n' ' ')
  printf '%-10s %7d %7d %7d  %s\n' $f $p $s $g "$c"
done
