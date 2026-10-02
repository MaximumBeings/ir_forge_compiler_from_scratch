// Chapter 29: each mistake in the attention examples is reported at compile time with the file and line.
// RUN: %not %mgc29 run %ex29/errors/e1_wrong_sequence_length.mg 2>&1 | %FileCheck %s --check-prefix=E1
// RUN: %not %mgc29 run %ex29/errors/e2_exp_of_a_scalar.mg 2>&1 | %FileCheck %s --check-prefix=E2
// RUN: %not %mgc29 run %ex29/errors/e3_q_and_k_widths_differ.mg 2>&1 | %FileCheck %s --check-prefix=E3
// RUN: %not %mgc29 run %ex29/errors/e4_softmax_over_a_variable_length.mg 2>&1 | %FileCheck %s --check-prefix=E4
// E1: e1_wrong_sequence_length.mg:5: error: argument shape 4x2 does not fit parameter 3x2
// E2: e2_exp_of_a_scalar.mg:2: error: exp needs a matrix, not a scalar
// E3: e3_q_and_k_widths_differ.mg:4: error: cannot multiply (matmul) shapes 3x2 and 3x3: inner dimensions differ
// E4: e4_softmax_over_a_variable_length.mg:3: error: broadcasting needs static shapes; this operand has a '?' dimension
