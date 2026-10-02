// Chapter 2's own example programs under the CURRENT compiler. The valid one still parses and prints; the two invalid ones are rejected
// (Chapter 2's compiler accepted the mismatched add; Chapter 3 added the check, so rejecting it now is the later, correct behavior).
// RUN: %mg-opt %docs/part2/code/mountain_goat.mlir | %FileCheck %s --check-prefix=OK
// RUN: %not %mg-opt %docs/part2/code/bad_transpose.mlir 2>&1 | %FileCheck %s --check-prefix=TRANSPOSE
// RUN: %not %mg-opt %docs/part2/code/mismatched_add.mlir 2>&1 | %FileCheck %s --check-prefix=ADD
// OK: mg.constant
// OK: mg.add
// OK: mg.transpose
// OK: mg.print
// TRANSPOSE: error: 'mg.transpose' op mg.transpose result shape must be the input shape reversed
// ADD: error: 'mg.add' op mg.add operands and result must have the same rank
