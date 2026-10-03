// Chapter 35: each mistake in the stacked-attention examples is reported at compile time, with the file and line.
// RUN: %not %mgc32 run %ex35/errors/e1_mask_of_the_wrong_size.mg 2>&1 | %FileCheck %s --check-prefix=E1
// RUN: %not %mgc32 run %ex35/errors/e2_missing_argument.mg 2>&1 | %FileCheck %s --check-prefix=E2
// RUN: %not %mgc32 run %ex35/errors/e3_stacked_rows_do_not_match.mg 2>&1 | %FileCheck %s --check-prefix=E3
// E1: e1_mask_of_the_wrong_size.mg:5: error: cannot add shapes 6x6 and 4x4: dimensions 6 and 4 differ and neither is 1
// E2: e2_missing_argument.mg:5: error: ln_back takes 3 arguments, got 2
// E3: e3_stacked_rows_do_not_match.mg:4: error: cannot multiply shapes 6x3 and 4x1: dimensions 6 and 4 differ and neither is 1
