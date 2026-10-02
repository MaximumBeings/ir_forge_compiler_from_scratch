// Chapter 28: the examples compile and run in Mountain Goat itself and print the values the page shows.
// RUN: %mgc28 run %ex28/01_reshape_and_permute.mg | %FileCheck %s --check-prefix=X1
// RUN: %mgc28 run %ex28/02_matmul_is_a_contraction.mg | %FileCheck %s --check-prefix=X2
// RUN: %mgc28 run %ex28/03_double_contraction.mg | %FileCheck %s --check-prefix=X3
// RUN: %mgc28 run %ex28/04_axis_at_the_front.mg | %FileCheck %s --check-prefix=X4
// RUN: %mgc28 run %ex28/05_axes_in_reverse_order.mg | %FileCheck %s --check-prefix=X5
// RUN: %mgc28 run %ex28/06_vectors_dot_and_outer.mg | %FileCheck %s --check-prefix=X6
// RUN: %mgc28 run %ex28/07_rank4_result.mg | %FileCheck %s --check-prefix=X7
// RUN: %mgc28 run %ex28/08_in_a_function.mg | %FileCheck %s --check-prefix=X8
// X1: rank = 3 {{.*}} sizes = [2, 3, 4]
// X1: 1, 2, 3, 4],
// X1: rank = 3 {{.*}} sizes = [3, 2, 4]
// X1: 1, 2, 3, 4],
// X1-NEXT: 13, 14, 15, 16]],
// X1: 5, 6, 7, 8],
// X1-NEXT: 17, 18, 19, 20]],
// X1: rank = 3 {{.*}} sizes = [4, 2, 3]
// X1: 1, 5, 9],
// X1-NEXT: 13, 17, 21]],
// X1: 2, 6, 10],
// X1: rank = 2 {{.*}} sizes = [4, 6]
// X1: 19, 20, 21, 22, 23, 24]]
// X2: sizes = [3, 4]
// X2: 1, 2, 4, 5],
// X2-NEXT: 3, 4, 10, 11],
// X2-NEXT: 5, 6, 16, 17]]
// X2: sizes = [3, 4]
// X2: 1, 2, 4, 5],
// X2-NEXT: 3, 4, 10, 11],
// X2-NEXT: 5, 6, 16, 17]]
// X3: sizes = [2, 5]
// X3: 10, 5, 0, -5, -10],
// X3-NEXT: 2, 1, 0, -1, -2]]
// X4: sizes = [3, 4, 5]
// X4: 1, -1, 2, -2, 3],
// X4-NEXT: 2, -2, 4, -4, 6],
// X4: 12, -12, 24, -24, 36]]
// X5: sizes = [2, 2]
// X5: 1090, 1168],
// X5-NEXT: 90, 96]]
// X6: sizes = [1, 1]
// X6: 14]]
// X6: sizes = [3, 4]
// X6: 4, 5, 6, 7],
// X6-NEXT: 8, 10, 12, 14],
// X6-NEXT: 12, 15, 18, 21]]
// X6: rank = 1 {{.*}} sizes = [3]
// X6: 12, 5, 7]
// X7: rank = 4 {{.*}} sizes = [2, 2, 2, 2]
// X7: 4, 5],
// X7: 31, 32]]
// X8: sizes = [2, 5]
// X8: 12, 24, 36, 48, 60],
// X8-NEXT: 24, 48, 72, 96, 120]]
