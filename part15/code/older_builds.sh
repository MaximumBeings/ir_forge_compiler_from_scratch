#!/bin/sh
# Point the SAME suite at two older mg-opt builds to show the tests can fail:
#   - Chapter 7's build (no dynamic shapes at all), assembled from Chapters 3, 5, 6, 7's own files
#   - Chapter 13's build (dynamic shapes, no runtime check), built by Chapter 13's own build.sh
# READ THIS FIRST: this script runs the SAME test suite against two OLDER builds of the compiler on purpose.
#   FAIL lines (and non-zero exit statuses) in this script's output are the EXPECTED result: each older build lacks features the tests check (Chapter 7: no dynamic shapes; Chapter 13: no run-time check), so the tests that need them SHOULD fail. That proves the tests can fail.
#   The unmodified, current build is the baseline and must show no failures. A mutation or old build that makes NO test fail would be the problem.
echo "NOTE: this script deliberately runs broken or older code. FAIL lines below are EXPECTED: they show the tests can detect the problem. The baseline (unmodified current build) must show none."
set -e
HERE=$(cd "$(dirname "$0")" && pwd); D=$HERE/../..; W=$HERE/work/ch7; T=$W/tree
mkdir -p $T/include/mg $T/lib $T/tools $W/build/include/mg
cp $D/part7/code/CMakeLists.txt $T/
cp $D/part3/code/MgDialect.td $D/part3/code/MgOps.td $D/part3/code/MgDialect.h $D/part3/code/MgOps.h $T/include/mg/
cp $D/part3/code/MgDialect.cpp $D/part5/code/LowerToAffine.cpp $D/part6/code/MgBufferizableOpInterfaceImpl.cpp $T/lib/
cp $D/part7/code/mg-opt.cpp $T/tools/
(cd $W/build && cmake $T -DMLIR_DIR=/usr/lib/llvm-18/lib/cmake/mlir -DLLVM_DIR=/usr/lib/llvm-18/lib/cmake/llvm \
   -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=OFF >/dev/null 2>&1 && make -j8 2>&1 | tail -1)
[ -x $D/part13/code/build/mg-opt ] || $D/part13/code/build.sh | tail -1
for b in "Chapter 7 build (no dynamic shapes):$W/build/mg-opt" "Chapter 13 build (dynamic shapes, no runtime check):$D/part13/code/build/mg-opt"; do
  echo "=================== ${b%%:*}"
  MG_OPT=${b#*:} MG_TEST_TMP=$HERE/work/old-out lit "$HERE/test" 2>&1 | grep -E "^FAIL|Passed|Failed:" | sed 's/IR Forge \/ Mountain Goat :: //;s/ ([0-9]* of [0-9]*)//' | sort -u
done
