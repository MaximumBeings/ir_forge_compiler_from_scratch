// Operator precedence and algebraic identities, checked through the whole compiler.
// RUN: %mgc21 run %ex21/06_precedence.mg | %FileCheck %s --check-prefix=PREC
// RUN: %mgc21 run %ex21/09_identity.mg | %FileCheck %s --check-prefix=ID
// PREC: 2, 6],
// PREC-NEXT: 12, 20]]
// PREC: 2, 8],
// PREC-NEXT: 18, 32]]
// PREC: 0, 0],
// PREC: 9, 8],
// PREC: 14, 28],
// PREC-NEXT: 42, 56]]
// ID: 3, 1],
// ID-NEXT: 4, 1]]
// ID: 0, 0],
// ID: 1, 1],
// ID: 3, 1],
// ID-NEXT: 4, 1]]
