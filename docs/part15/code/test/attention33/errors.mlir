// Chapter 33: each shape mistake in the attention programs is reported at compile time, with the file and line.
// RUN: %not %mgc32 run %ex33/errors/e1_one_sequence_short.mg 2>&1 | %FileCheck %s --check-prefix=E1
// RUN: %not %mgc32 run %ex33/errors/e2_group_matrix_transposed.mg 2>&1 | %FileCheck %s --check-prefix=E2
// RUN: %not %mgc32 run %ex33/errors/e3_reshape_element_count.mg 2>&1 | %FileCheck %s --check-prefix=E3
// E1: e1_one_sequence_short.mg:5: error: argument shape 92x5 does not fit parameter 96x5
// E2: e2_group_matrix_transposed.mg:8: error: argument shape 96x24 does not fit parameter 24x96
// E3: e3_reshape_element_count.mg:3: error: cannot reshape 8x1 (8 elements) to 4x3 (12 elements)
