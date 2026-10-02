#!/bin/sh
# Compile ops.mg with mgc, then build and run the C++ program against it. Output: run_out.txt
HERE=$(cd "$(dirname "$0")" && pwd); W=$HERE/../work/cpp; mkdir -p $W
$HERE/../mgc lib $HERE/ops.mg -o $W
cp $W/ops.h $HERE/ops_generated.h
clang++-18 -std=c++17 -Wall -I$W $HERE/app.cpp $W/ops.o -o $W/app
echo "--- ./app"; $W/app
