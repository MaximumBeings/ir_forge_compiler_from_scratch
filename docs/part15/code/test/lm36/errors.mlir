// Chapter 36: each mistake in the two-head, two-block examples is reported at compile time, with the file and line.
// RUN: %not %mgc32 run %ex36/errors/e1_head_output_of_the_wrong_width.mg 2>&1 | %FileCheck %s --check-prefix=E1
// RUN: %not %mgc32 run %ex36/errors/e2_missing_argument.mg 2>&1 | %FileCheck %s --check-prefix=E2
// RUN: %not %mgc32 run %ex36/errors/e3_residual_of_the_wrong_width.mg 2>&1 | %FileCheck %s --check-prefix=E3
// E1: e1_head_output_of_the_wrong_width.mg:4: error: cannot multiply (matmul) shapes 6x4 and 2x8: inner dimensions differ
// E2: e2_missing_argument.mg:5: error: ln_back takes 3 arguments, got 2
// E3: e3_residual_of_the_wrong_width.mg:4: error: cannot add shapes 6x8 and 6x4: dimensions 8 and 4 differ and neither is 1
