// Chapter 31: each mistake in the training examples is reported at compile time, with the file and line.
// RUN: %not %mgc31 run %ex31/errors/e1_wrong_number_of_pairs.mg 2>&1 | %FileCheck %s --check-prefix=E1
// RUN: %not %mgc31 run %ex31/errors/e2_log_of_a_scalar.mg 2>&1 | %FileCheck %s --check-prefix=E2
// RUN: %not %mgc31 run %ex31/errors/e3_weights_the_wrong_size.mg 2>&1 | %FileCheck %s --check-prefix=E3
// E1: e1_wrong_number_of_pairs.mg:7: error: argument shape 13x5 does not fit parameter 14x5
// E2: e2_log_of_a_scalar.mg:2: error: log needs a matrix, not a scalar
// E3: e3_weights_the_wrong_size.mg:9: error: argument shape 4x5 does not fit parameter 5x5
