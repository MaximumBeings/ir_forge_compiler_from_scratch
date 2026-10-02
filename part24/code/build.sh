#!/bin/sh
# Rebuild mg-opt for Chapter 24: Chapter 22's build with this directory's LowerToAffine.cpp (mg.matmul gains an `ikj` loop order,
# chosen with --convert-mg-to-affine=matmul-order=ikj; the default stays ijk). Produces ./build/mg-opt.
# Needs mlir-18-tools, libmlir-18-dev, llvm-18-dev, cmake, make.
set -e
HERE=$(cd "$(dirname "$0")" && pwd); D=$HERE/../..; T=$HERE/tree
mkdir -p $T/include/mg $T/lib $T/tools
cp $HERE/CMakeLists.txt $T/
cp $D/part3/code/MgDialect.td $D/part22/code/MgOps.td $D/part3/code/MgDialect.h $D/part3/code/MgOps.h $T/include/mg/
cp $D/part14/code/DynamicShapes.h $T/include/mg/
cp $D/part22/code/MgDialect.cpp $T/lib/
cp $D/part14/code/MgBufferizableOpInterfaceImpl.cpp $T/lib/
cp $D/part19/code/AssertToStderr.cpp $T/lib/
cp $HERE/LowerToAffine.cpp $T/lib/
cp $HERE/mg-opt.cpp $T/tools/
mkdir -p $HERE/build/include/mg && cd $HERE/build
cmake $T -DMLIR_DIR=/usr/lib/llvm-18/lib/cmake/mlir -DLLVM_DIR=/usr/lib/llvm-18/lib/cmake/llvm \
  -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=OFF > cmake_out.txt 2>&1
make -j8 2>&1 | tail -2
