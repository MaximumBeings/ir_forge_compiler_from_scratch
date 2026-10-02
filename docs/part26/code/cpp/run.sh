#!/bin/sh
# Compile gd.mg (optimized, with the faster matmul loop order from Chapter 24), build the C++ trainer against it, run it. Output: run_out.txt
HERE=$(cd "$(dirname "$0")" && pwd); W=$HERE/../work/train; mkdir -p $W
$HERE/../../../part24/code/mgc lib $HERE/gd.mg -o $W -O2 --matmul-order ikj > /dev/null
cp $W/gd.h $HERE/gd_generated.h
clang++-18 -std=c++17 -O2 -Wall -I$W $HERE/train.cpp $W/gd.o -o $W/train
$W/train
