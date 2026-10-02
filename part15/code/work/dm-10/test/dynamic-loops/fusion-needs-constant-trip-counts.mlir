// Chapter 18: the RULE behind Chapter 17's "fusion declines on dynamic bounds", found by reading LoopFusion.cpp and testing it:
// --affine-loop-fusion needs every loop in both nests to have a CONSTANT trip count. Dynamic BUFFERS do not matter (B fuses);
// a dynamic bound on ANY single loop (A: all of them; E, F: producer outer/inner; G: consumer) makes it decline silently.
// Pinned for this toolchain version only: if a newer LLVM relaxes the rule, the DECLINES runs fail, which is the signal to revisit Chapter 18.
// RUN: %mg-opt %inputs/exp_C.mlir --affine-loop-fusion | %FileCheck %s --check-prefix=FUSES
// RUN: %mg-opt %inputs/exp_B.mlir --affine-loop-fusion | %FileCheck %s --check-prefix=FUSES
// RUN: %mg-opt %inputs/exp_A.mlir --affine-loop-fusion | %FileCheck %s --check-prefix=DECLINES
// RUN: %mg-opt %inputs/exp_E.mlir --affine-loop-fusion | %FileCheck %s --check-prefix=DECLINES
// RUN: %mg-opt %inputs/exp_F.mlir --affine-loop-fusion | %FileCheck %s --check-prefix=DECLINES
// RUN: %mg-opt %inputs/exp_G.mlir --affine-loop-fusion | %FileCheck %s --check-prefix=DECLINES
// FUSES-COUNT-2: affine.for
// FUSES-NOT: affine.for
// DECLINES-COUNT-4: affine.for
// DECLINES-NOT: affine.for
