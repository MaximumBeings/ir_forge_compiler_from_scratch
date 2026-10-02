// Chapter 19: a program with no cf.assert (any static program) passes through the pass byte for byte.
// RUN: %mg-opt %inputs/static_add.mlir --convert-mg-to-affine -o %t.before.mlir
// RUN: %mg-opt %t.before.mlir --mg-lower-assert-to-stderr -o %t.after.mlir
// RUN: cmp %t.before.mlir %t.after.mlir
