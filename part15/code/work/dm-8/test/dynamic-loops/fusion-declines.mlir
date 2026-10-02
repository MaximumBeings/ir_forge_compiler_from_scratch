// Chapter 17: PINS AN OBSERVED LIMITATION. --affine-loop-fusion leaves a dynamic-bound nest pair alone: 4 loops in, 4 out
// (the same pair with static bounds fuses 4 -> 2, see loops/fusion.mlir). The cause was not established. If a newer
// toolchain starts fusing these, this test fails: that is the signal to revisit Chapter 17, not a regression.
// RUN: %mg-opt %inputs/chain.mlir --convert-mg-to-affine | %mg-opt --affine-loop-fusion | %FileCheck %s
// CHECK-COUNT-4: affine.for
// CHECK-NOT: affine.for
