// Chapter 18: PINS A TOOLCHAIN BUG (LLVM 18.1.3). Running --affine-loop-fusion on a TILED nest with dynamic bounds produces INVALID IR:
// the pass's sinkSequentialLoops step swaps the tile loops inward past the point loops whose bounds use the tile induction variables.
// The same pass on a tiled STATIC nest is fine. If a newer LLVM fixes this, the DYN run fails: that is the signal to revisit Chapter 18.
// RUN: %mg-opt %inputs/chain.mlir --convert-mg-to-affine | %mg-opt --affine-loop-tile="tile-size=4" -o %t.dyn.mlir
// RUN: %not %mg-opt %t.dyn.mlir --affine-loop-fusion 2>&1 | %FileCheck %s --check-prefix=DYN
// RUN: %mg-opt %inputs/static_chain.mlir --convert-mg-to-affine | %mg-opt --affine-loop-tile="tile-size=1" | %mg-opt --affine-loop-fusion | %FileCheck %s --check-prefix=STATIC1
// RUN: %mg-opt %inputs/static_chain.mlir --convert-mg-to-affine | %mg-opt --affine-loop-tile="tile-size=2" | %mg-opt --affine-loop-fusion | %FileCheck %s --check-prefix=STATIC2
// DYN: error: operand #0 does not dominate this use
// STATIC1-COUNT-4: affine.for
// STATIC1-NOT: affine.for
// STATIC2-COUNT-8: affine.for
// STATIC2-NOT: affine.for
