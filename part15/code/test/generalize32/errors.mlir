// Chapter 32: each mistake in the examples is reported at compile time, with the file and line.
// RUN: %not %mgc32 run %ex32/errors/e1_ge_of_a_scalar.mg 2>&1 | %FileCheck %s --check-prefix=E1
// RUN: %not %mgc32 run %ex32/errors/e2_ge_shapes_differ.mg 2>&1 | %FileCheck %s --check-prefix=E2
// RUN: %not %mgc32 run %ex32/errors/e3_held_out_pairs_to_the_training_loss.mg 2>&1 | %FileCheck %s --check-prefix=E3
// E1: e1_ge_of_a_scalar.mg:2: error: ge compares two matrices, not a scalar; write a scalar threshold as a 1x1 matrix
// E2: e2_ge_shapes_differ.mg:2: error: cannot compare shapes 2x3 and 3x2: dimensions 2 and 3 differ and neither is 1
// E3: e3_held_out_pairs_to_the_training_loss.mg:7: error: argument shape 4x5 does not fit parameter 10x5
