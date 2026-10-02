// Chapter 22: relu, reductions, mean, broadcasting, with exact values.
// RUN: %mgc22 run %ex22/01_relu.mg | %FileCheck %s --check-prefix=RELU
// RUN: %mgc22 run %ex22/02_row_and_col_sums.mg | %FileCheck %s --check-prefix=SUMS
// RUN: %mgc22 run %ex22/03_max_and_mean.mg | %FileCheck %s --check-prefix=MM
// RUN: %mgc22 run %ex22/04_broadcast_bias.mg | %FileCheck %s --check-prefix=BC
// RELU: sizes = [2, 3]
// RELU: 1, 0, 3],
// RELU-NEXT: 0, 5, 0]]
// SUMS: sizes = [2, 1]
// SUMS: 6],
// SUMS-NEXT: 15]]
// SUMS: sizes = [1, 3]
// SUMS: 5, 7, 9]]
// MM: 9],
// MM-NEXT: 8]]
// MM: 8, 9, 6]]
// MM: 4.33333],
// MM-NEXT: 6.33333]]
// MM: 4.5, 7, 4.5]]
// BC: 101, 202, 303],
// BC-NEXT: 104, 205, 306]]
// BC: 11, 12, 13],
// BC-NEXT: 24, 25, 26]]
// BC: 2, 4, 6],
// BC-NEXT: 8, 10, 12]]
// Broadcasting with the small operand on the LEFT (this was a test gap, found by a mutation: see Chapter 22).
// RUN: %mgc22 run %ex22/12_broadcast_left.mg | %FileCheck %s --check-prefix=LEFT
// LEFT: 11, 22, 33],
// LEFT-NEXT: 14, 25, 36]]
// LEFT: 9, 18, 27],
// LEFT-NEXT: 6, 15, 24]]
// LEFT: 99, 98, 97],
// LEFT-NEXT: 196, 195, 194]]
// LEFT: 2, 4, 6],
// LEFT-NEXT: 8, 10, 12]]
// The max of all-negative numbers is negative (a max reduction that starts from 0 gets this wrong; found by a mutation).
// RUN: %mgc22 run %ex22/13_negative_max.mg | %FileCheck %s --check-prefix=NEG
// NEG: sizes = [2, 1]
// NEG: -1],
// NEG-NEXT: -2]]
// NEG: sizes = [1, 2]
// NEG: -3, -1]]
