// Chapter 19: an assert nested in a single-block region (an affine.for body) cannot be split into blocks, so the pass LEAVES IT
// (valid IR, still a cf.assert). Run after --lower-affine --convert-scf-to-cf, where no structured control flow remains, the same
// assert IS rewritten. Without the guard the first run produced `'affine.for' op expects region #0 to have 0 or 1 blocks`.
// RUN: %mg-opt %inputs/nested.mlir --mg-lower-assert-to-stderr | %FileCheck %s --check-prefix=LEFT
// RUN: %mg-opt %inputs/nested.mlir --lower-affine --convert-scf-to-cf --mg-lower-assert-to-stderr | %FileCheck %s --check-prefix=REWRITTEN
// LEFT: cf.assert {{.*}}, "value is NaN"
// REWRITTEN-NOT: cf.assert
// REWRITTEN: llvm.call @write
