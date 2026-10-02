// Chapter 20: the remaining runnable examples (06 transpose twice, 07 expressions, 08 functions).
// RUN: %mgc run %ex/06_transpose_twice.mg | %FileCheck %s --check-prefix=TT
// RUN: %mgc run %ex/07_expressions.mg | %FileCheck %s --check-prefix=EXPR
// RUN: %mgc run %ex/08_functions.mg | %FileCheck %s --check-prefix=FN
// TT: sizes = [3, 2]
// TT: 1, 4],
// TT: sizes = [2, 3]
// TT: 1, 2, 3],
// TT-NEXT: 4, 5, 6]]
// EXPR: 111, 222],
// EXPR-NEXT: 333, 444]]
// EXPR: 11, 23],
// EXPR-NEXT: 32, 44]]
// FN: 2, 4],
// FN-NEXT: 6, 8]]
// FN: 4, 8],
// FN-NEXT: 12, 16]]
