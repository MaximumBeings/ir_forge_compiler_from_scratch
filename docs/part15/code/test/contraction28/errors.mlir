// Chapter 28: every mistake the new operations can catch is reported at compile time, with the file and line, and produces no program.
// RUN: %not %mgc28 run %ex28/errors/e1_axis_size_mismatch.mg 2>&1 | %FileCheck %s --check-prefix=E1
// RUN: %not %mgc28 run %ex28/errors/e2_lists_differ_in_length.mg 2>&1 | %FileCheck %s --check-prefix=E2
// RUN: %not %mgc28 run %ex28/errors/e3_axis_out_of_range.mg 2>&1 | %FileCheck %s --check-prefix=E3
// RUN: %not %mgc28 run %ex28/errors/e4_axis_listed_twice.mg 2>&1 | %FileCheck %s --check-prefix=E4
// RUN: %not %mgc28 run %ex28/errors/e5_reshape_element_count.mg 2>&1 | %FileCheck %s --check-prefix=E5
// RUN: %not %mgc28 run %ex28/errors/e6_not_a_permutation.mg 2>&1 | %FileCheck %s --check-prefix=E6
// RUN: %not %mgc28 run %ex28/errors/e7_arithmetic_on_rank3.mg 2>&1 | %FileCheck %s --check-prefix=E7
// RUN: %not %mgc28 run %ex28/errors/e8_dynamic_shape.mg 2>&1 | %FileCheck %s --check-prefix=E8
// E1: e1_axis_size_mismatch.mg:4: error: contract: axis 1 of the first tensor has size 2 but axis 0 of the second has size 4
// E2: e2_lists_differ_in_length.mg:3: error: contract: the two axis lists must have the same length
// E3: e3_axis_out_of_range.mg:3: error: contract: axis 5 is out of range for the first tensor (shape 2x2)
// E4: e4_axis_listed_twice.mg:3: error: contract: axis 1 is listed twice for the first tensor
// E5: e5_reshape_element_count.mg:3: error: cannot reshape 2x3 (6 elements) to 4x2 (8 elements)
// E6: e6_not_a_permutation.mg:3: error: permute: a rank-3 tensor needs each of the axes 0..2 listed exactly once, got 0, 0, 2
// E7: e7_arithmetic_on_rank3.mg:3: error: '+' works on matrices (rank 2), but this value has shape 2x2x2 (rank 3); use reshape, permute or contract
// E8: e8_dynamic_shape.mg:2: error: reshape needs a static shape; this value has a '?' dimension (?x4)
