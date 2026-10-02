// Chapter 28: contract(...) agrees EXACTLY with the definition of a contraction (plain nested loops, no matrix product) on 13 shape combinations,
// with whole numbers and with quarters. The script exits non-zero if any case disagrees, so lit fails the test.
// RUN: env MG_OPT=%mg-opt python3 %ch28/check_contractions.py | %FileCheck %s
// CHECK: -- whole numbers
// CHECK: ok   matrix product
// CHECK: ok   rank 5 operand
// CHECK: ok   size-1 axes
// CHECK: -- quarters
// CHECK: ok   rank 5 operand
// CHECK: all cases agree with the definition
// CHECK-NOT: FAIL
