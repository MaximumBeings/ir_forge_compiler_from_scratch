// Chapter 21: real programs, real arithmetic. Subtract, Hadamard, matmul, scalars.
// RUN: %mgc21 run %ex21/01_subtract.mg | %FileCheck %s --check-prefix=SUB
// RUN: %mgc21 run %ex21/02_hadamard.mg | %FileCheck %s --check-prefix=HAD
// RUN: %mgc21 run %ex21/04_matmul.mg | %FileCheck %s --check-prefix=MM
// RUN: %mgc21 run %ex21/05_scalar_ops.mg | %FileCheck %s --check-prefix=SC
// SUB: 9, 18, 27],
// SUB-NEXT: 36, 45, 54]]
// SUB: -9, -18, -27],
// HAD: 2, 4, 6],
// HAD-NEXT: 12, 15, 18]]
// MM: sizes = [2, 2]
// MM: 58, 64],
// MM-NEXT: 139, 154]]
// MM: sizes = [3, 3]
// MM: 39, 54, 69],
// MM-NEXT: 49, 68, 87],
// MM-NEXT: 59, 82, 105]]
// SC: 11, 12],
// SC: 0, 1],
// SC: 9, 8],
// SC: 0.5, 1],
// SC: 16, 8],
// SC: 0.25, 0.5],
