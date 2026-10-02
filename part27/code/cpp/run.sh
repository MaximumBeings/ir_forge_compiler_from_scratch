#!/bin/sh
# Compile contract.mg (optimized, ikj loop order), build the C++ demo against it and run it; then run the two "trap" modes. Output: run_out.txt
HERE=$(cd "$(dirname "$0")" && pwd); W=$HERE/../work/contract; mkdir -p $W
$HERE/../../../part24/code/mgc lib $HERE/contract.mg -o $W -O2 --matmul-order ikj > /dev/null
cp $W/contract.h $HERE/contract_generated.h
clang++-18 -std=c++17 -O2 -Wall -Wextra -I$W -I$HERE $HERE/contract_demo.cpp $W/contract.o -o $W/contract_demo
echo "--- ./contract_demo"; $W/contract_demo; echo "(exit status $?)"
echo; echo "--- ./contract_demo trap          (the axis check on)"; $W/contract_demo trap
echo; echo "--- ./contract_demo trap skip     (the axis check skipped: what does Mountain Goat's own run-time check say?)"
$W/contract_demo trap skip; echo "(exit status $?)"
