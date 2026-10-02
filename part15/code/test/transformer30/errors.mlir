// Chapter 30: each mistake in the transformer examples is reported at compile time, with the file and line.
// RUN: %not %mgc30 run %ex30/errors/e1_wrong_number_of_tokens.mg 2>&1 | %FileCheck %s --check-prefix=E1
// RUN: %not %mgc30 run %ex30/errors/e2_missing_argument.mg 2>&1 | %FileCheck %s --check-prefix=E2
// RUN: %not %mgc30 run %ex30/errors/e3_sqrt_of_a_scalar.mg 2>&1 | %FileCheck %s --check-prefix=E3
// RUN: %not %mgc30 run %ex30/errors/e4_residual_shapes_differ.mg 2>&1 | %FileCheck %s --check-prefix=E4
// E1: e1_wrong_number_of_tokens.mg:3: error: argument shape 3x4 does not fit parameter 4x4
// E2: e2_missing_argument.mg:10: error: attention_sublayer takes 12 arguments, got 11
// E3: e3_sqrt_of_a_scalar.mg:2: error: sqrt needs a matrix, not a scalar
// E4: e4_residual_shapes_differ.mg:4: error: cannot add shapes 4x4 and 4x2: dimensions 4 and 2 differ and neither is 1
