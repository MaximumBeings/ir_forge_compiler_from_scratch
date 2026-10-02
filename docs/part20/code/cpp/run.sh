#!/bin/sh
# Compile kernels.mg with mgc, then build and run the C++ program against it. Output: run_out.txt
HERE=$(cd "$(dirname "$0")" && pwd); W=$HERE/../work/cpp; mkdir -p $W
$HERE/../mgc lib $HERE/kernels.mg -o $W
cp $W/kernels.h $HERE/kernels_generated.h
clang++-18 -std=c++17 -Wall -I$W $HERE/app.cpp $W/kernels.o -o $W/app
echo "--- ./app"; $W/app
echo "--- ./app mismatch   (exit status follows)"; $W/app mismatch; echo "exit=$?"
