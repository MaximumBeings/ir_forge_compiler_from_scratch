// Chapter 17: the control for fusion-declines: the SAME add-then-transpose chain with static 4x6 bounds does fuse (4 -> 2 loops).
// RUN: %mg-opt %inputs/static_chain.mlir --convert-mg-to-affine | %mg-opt --affine-loop-fusion | %FileCheck %s
// CHECK-COUNT-2: affine.for
// CHECK-NOT: affine.for
