#!/bin/sh
# Chapter 12's claims about THIS repository, as commands. Run from docs/part12/code. Output: checks_out.txt
D=$(cd "$(dirname "$0")/../.." && pwd)
echo "### A. passes the real pipelines use: does ANY chapter (1-12) or any code directory mention them?"
for p in "cse" "strip-debug-info" "expand-strided-metadata" "convert-math-to-llvm" "convert-index-to-llvm" "convert-vector-to-scf" "linalg"; do
  hits=$(grep -rlE -- "$p" $D/part[1-9]/ $D/part10/ $D/part11/ 2>/dev/null | wc -l)
  printf "%-26s files mentioning it: %s\n" "$p" "$hits"
done
echo
echo "### B. tensor/memref types appearing in every chapter's .mlir files (count, type):"
grep -rhoE "tensor<[^>]*>|memref<[^>]*>" $D/part[1-9]/code $D/part10/code $D/part11/code --include=*.mlir | sort | uniq -c | sort -rn | head -8
echo
echo "### C. any dynamic (?) dimension in any .mlir file of Chapters 1-11?"
grep -rlE "\?x|x\?" $D/part[1-9]/code $D/part10/code $D/part11/code --include=*.mlir | wc -l | sed 's/^/files containing a ? dimension: /'
echo
echo "### D. files tracked OUTSIDE docs/ (from the repository root). When Chapter 12 was written this was the whole list;"
echo "###    the test suite added in Chapter 15 lives INSIDE docs/ (docs/part15/code/test), so it does not show up here."
git -C "$D/.." ls-files | grep -v "^docs/" 
echo
echo "### E. the four mg operations, and their element type:"
grep -n "^def .*Op :" $D/part3/code/MgOps.td
grep -n "F64" $D/part3/code/MgOps.td | head -4
