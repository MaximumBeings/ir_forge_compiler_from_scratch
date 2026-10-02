// neg on its own (static and dynamic), and division on dynamic shapes where order matters.
// RUN: %mgc21 run %ex21/16_negate.mg | %FileCheck %s --check-prefix=NEG
// RUN: %mgc21 run %ex21/17_dynamic_divide.mg | %FileCheck %s --check-prefix=DIV
// NEG: sizes = [1, 3]
// NEG: -1, 2, -3]]
// NEG: sizes = [1, 2]
// NEG: -0.5, 4]]
// NEG: sizes = [2, 1]
// NEG: -7],
// NEG-NEXT: 8]]
// DIV: sizes = [2, 2]
// DIV: 0.5, 0.5],
// DIV-NEXT: 3, 0.75]]
