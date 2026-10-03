// Chapter 37: every claim the chapter makes about what LLVM does with Mountain Goat's loops is tested by running LLVM's tools: the IR's shape, what `opt` does pass by
// pass, the vectorizer's stated reasons for ijk and ikj (and the effect of the reassoc flag), whether -ffast-math changes a .ll file (it does not), which operations
// vectorize, and what the backend and llvm-mca say. The expected values are those of an x86-64 machine with AVX2 or newer (the checks use -march=native).
// RUN: python3 %ch37/check_llvm.py | %FileCheck %s
// CHECK: -- 1. reading the IR
// CHECK: ok   the 2x2 add: one fadd, one malloc
// CHECK: -- 2. the passes (opt)
// CHECK: ok   after loop-vectorize the ikj order has a vector fmul
// CHECK: ok   the whole -O3 pipeline turns ijk's malloc and zero-fill loop into one calloc
// CHECK: -- 3. the vectorizer's reasons
// CHECK: ok   ijk: not vectorized, 'cannot prove it is safe to reorder floating-point operations'
// CHECK: ok   ijk with the reassoc flag on its fadd: 'vectorized loop'
// CHECK: ok   the vectorized ijk gathers the column of b
// CHECK: ok   clang's -ffast-math on the unchanged .ll leaves the assembly byte for byte identical
// CHECK: -- 4. the operations
// CHECK: ok   exp: no packed arithmetic, a library call to ['exp']
// CHECK: -- 5. the backend
// CHECK: ok   ikj: no fused multiply-add (0); with the contract flag
// CHECK: ok   llvm-mca: ijk
// CHECK: all checks pass
// CHECK-NOT: FAIL
