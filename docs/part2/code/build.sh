#!/bin/sh
# Build Chapter 2's mg-opt from the book's own files (this chapter's files, plus the earlier chapters' files it still uses).
# Produces ./build/mg-opt. Needs mlir-18-tools, libmlir-18-dev, llvm-18-dev, cmake, make.
set -e
HERE=$(cd "$(dirname "$0")" && pwd); D=$HERE/../..; T=$HERE/tree
mkdir -p $T/include/mg $T/lib $T/tools
cp $D/part2/code/CMakeLists.txt $T/
cp $D/part2/code/MgDialect.td $D/part2/code/MgOps.td $D/part2/code/MgDialect.h $D/part2/code/MgOps.h $T/include/mg/
cp $D/part2/code/MgDialect.cpp $T/lib/
cp $D/part2/code/mg-opt.cpp $T/tools/
mkdir -p $HERE/build/include/mg && cd $HERE/build
cmake $T -DMLIR_DIR=/usr/lib/llvm-18/lib/cmake/mlir -DLLVM_DIR=/usr/lib/llvm-18/lib/cmake/llvm \
  -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=OFF > cmake_out.txt 2>&1
make -j8 2>&1 | tail -2
