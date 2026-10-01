#!/bin/sh
# Rebuild mg-opt: earlier chapters' latest files, with this chapter's overrides. Produces ./build/mg-opt.
# Needs mlir-18-tools, libmlir-18-dev, llvm-18-dev, cmake, make.
set -e
HERE=$(cd "$(dirname "$0")" && pwd); D=$HERE/../..; T=$HERE/tree
mkdir -p $T/include/mg $T/lib $T/tools
cp $HERE/CMakeLists.txt $T/
cp $D/part3/code/MgDialect.td $D/part3/code/MgOps.td $D/part3/code/MgDialect.h $D/part3/code/MgOps.h $T/include/mg/
cp $HERE/DynamicShapes.h $T/include/mg/
cp $D/part13/code/MgDialect.cpp $T/lib/
cp $HERE/LowerToAffine.cpp $HERE/MgBufferizableOpInterfaceImpl.cpp $T/lib/
cp $HERE/mg-opt.cpp $T/tools/
mkdir -p $HERE/build/include/mg && cd $HERE/build
cmake $T -DMLIR_DIR=/usr/lib/llvm-18/lib/cmake/mlir -DLLVM_DIR=/usr/lib/llvm-18/lib/cmake/llvm \
  -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=OFF > cmake_out.txt 2>&1
make -j8 2>&1 | tail -2
