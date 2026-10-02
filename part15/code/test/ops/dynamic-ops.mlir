// One compiled matmul / affine function, several shapes.
// RUN: %mgc21 run %ex21/10_dynamic_matmul.mg | %FileCheck %s --check-prefix=DM
// RUN: %mgc21 run %ex21/11_dynamic_scalar.mg | %FileCheck %s --check-prefix=DS
// DM: sizes = [2, 1]
// DM: 6],
// DM-NEXT: 15]]
// DM: sizes = [1, 2]
// DM: 13, 16]]
// DM: sizes = [1, 1]
// DM: 42]]
// DS: sizes = [1, 3]
// DS: 3, 5, 7]]
// DS: sizes = [2, 1]
// DS: 3],
// DS-NEXT: 5]]
// DS: sizes = [3, 2]
// DS: 1, 1],
// DS-NEXT: 1, 1],
// DS-NEXT: 1, 1]]
