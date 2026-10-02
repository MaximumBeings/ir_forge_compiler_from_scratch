// Division follows IEEE 754: 10/4 is 2.5; 0/0 is nan; -5/0 is -inf. No error, no abort.
// RUN: %mgc21 run %ex21/03_divide.mg | %FileCheck %s
// CHECK: 2.5, 2.5],
// CHECK-NEXT: {{-?nan}}, -inf]]
