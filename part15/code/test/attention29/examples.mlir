// Chapter 29: the examples compile and run and print the values the page shows (Python's math.exp gave the same numbers: see against-reference.mlir).
// Example 3 is the deliberate failure of the naive softmax: it prints inf and nan (the sign of a nan is meaningless, so only "nan" is matched).
// RUN: %mgc29 run %ex29/01_exp.mg | %FileCheck %s --check-prefix=X1
// RUN: %mgc29 run %ex29/02_softmax_naive.mg | %FileCheck %s --check-prefix=X2
// RUN: %mgc29 run %ex29/03_softmax_overflow.mg | %FileCheck %s --check-prefix=X3
// RUN: %mgc29 run %ex29/04_softmax_stable.mg | %FileCheck %s --check-prefix=X4
// RUN: %mgc29 run %ex29/05_temperature.mg | %FileCheck %s --check-prefix=X5
// RUN: %mgc29 run %ex29/06_attention.mg | %FileCheck %s --check-prefix=X6
// RUN: %mgc29 run %ex29/07_causal_attention.mg | %FileCheck %s --check-prefix=X7
// RUN: %mgc29 run %ex29/08_self_attention_block.mg | %FileCheck %s --check-prefix=X8
// X1: 1, 2.71828],
// X1-NEXT: 7.38906, 0.367879]]
// X1: 4.48169, 0.606531]]
// X1: 4.48169, 0.606531]]
// X2: 0.0900306, 0.244728, 0.665241],
// X2-NEXT: 0.333333, 0.333333, 0.333333]]
// X2: sizes = [2, 1]
// X2: 1],
// X2-NEXT: 1]]
// X3: inf, inf, inf]]
// X3: {{-?}}nan, {{-?}}nan, {{-?}}nan]]
// X4: 0.0900306, 0.244728, 0.665241],
// X4-NEXT: 0.0900306, 0.244728, 0.665241]]
// X4: 0.0900306, 0.244728, 0.665241],
// X4-NEXT: 0.0900306, 0.244728, 0.665241]]
// X4: 0.665241, 0.244728, 0.0900306],
// X4-NEXT: 0.333333, 0.333333, 0.333333]]
// X5: 0.0900306, 0.244728, 0.665241]]
// X5: 0.0158762, 0.11731, 0.866813]]
// X5: 0.254275, 0.326496, 0.419229]]
// X6: 0.401112, 0.197776, 0.401112],
// X6-NEXT: 0.197776, 0.401112, 0.401112],
// X6-NEXT: 0.248255, 0.248255, 0.50349]]
// X6: 6.01668, 3.98332],
// X6-NEXT: 3.98332, 6.01668],
// X6-NEXT: 5, 5]]
// X7: 1, 0, 0],
// X7-NEXT: 0.330238, 0.669762, 0],
// X7-NEXT: 0.248255, 0.248255, 0.50349]]
// X7: 10, 0],
// X7-NEXT: 3.30238, 6.69762],
// X7-NEXT: 5, 5]]
// X8: 2.14131, 1, 2, 1.14131],
// X8-NEXT: 1, 2, 1, 1],
// X8-NEXT: 2.14397, 2, 1, 2.14397]]
