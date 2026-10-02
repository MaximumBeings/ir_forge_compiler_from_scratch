// The language tour's examples compile, run and print what the page says they print.
// RUN: %mgc21 run %tour/01_first_program.mg | %FileCheck %s --check-prefix=T1
// RUN: %mgc21 run %tour/02_literals.mg | %FileCheck %s --check-prefix=T2
// RUN: %mgc21 run %tour/03_let_and_shadowing.mg | %FileCheck %s --check-prefix=T3
// RUN: %mgc21 run %tour/04_functions.mg | %FileCheck %s --check-prefix=T4
// RUN: %mgc21 run %tour/05_dynamic_types.mg | %FileCheck %s --check-prefix=T5
// RUN: %mgc21 run %tour/06_operators.mg | %FileCheck %s --check-prefix=T6
// T1: sizes = [2, 3]
// T1: 1, 2, 3],
// T1-NEXT: 4, 5, 6]]
// T2: sizes = [1, 3]
// T2: 1.5, -2, 300]]
// T2: sizes = [3, 1]
// T2: 6, -8, 1200]]
// T3: sizes = [1, 2]
// T3: 11, 21]]
// T4: sizes = [2, 2]
// T4: 6, 9],
// T4-NEXT: 12, 15]]
// T5: sizes = [1, 2]
// T5: 2, 4]]
// T5: sizes = [3, 1]
// T5: sizes = [2, 1]
// T5: 6],
// T5-NEXT: 15]]
// T6: 11, 22],
// T6: 9, 18],
// T6: 10, 40],
// T6-NEXT: 90, 160]]
// T6: 10, 10],
// T6: 70, 100],
// T6-NEXT: 150, 220]]
// T6: 1, 3],
// T6-NEXT: 2, 4]]
// T6: -1, -2],
// T6: 3, 5],
// T6-NEXT: 7, 9]]
