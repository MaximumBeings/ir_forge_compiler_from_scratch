// Chapter 17: full unrolling needs a constant trip count. With fully dynamic bounds it silently does nothing (4 loops stay 4);
// with a ?x2 shape the add nest's inner loop (trip count 2) is unrolled away (4 -> 3 loops) and the dynamic loops remain.
// RUN: %mg-opt %inputs/chain.mlir --convert-mg-to-affine | %mg-opt --affine-loop-unroll="unroll-full" | %FileCheck %s --check-prefix=DYN
// RUN: %mg-opt %inputs/chain2.mlir --convert-mg-to-affine | %mg-opt --affine-loop-unroll="unroll-full" | %FileCheck %s --check-prefix=PART
// DYN-COUNT-4: affine.for
// DYN-NOT: affine.for
// PART-COUNT-3: affine.for
// PART-NOT: affine.for
