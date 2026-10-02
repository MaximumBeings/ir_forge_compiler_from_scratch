// Reductions on dynamic shapes, and the rule that '?' is never broadcast.
// RUN: %mgc22 run %ex22/09_dynamic_reductions.mg | %FileCheck %s --check-prefix=DYN
// RUN: %mgc22 run %ex22/11_dynamic_no_broadcast.mg > %t.out 2> %t.err || true
// RUN: %FileCheck %s --input-file=%t.out --check-prefix=NB-OUT
// RUN: %FileCheck %s --input-file=%t.err --check-prefix=NB-ERR
// DYN: 6],
// DYN-NEXT: 15]]
// DYN: sizes = [4, 1]
// DYN: 7],
// DYN-NEXT: 8],
// DYN-NEXT: 9],
// DYN-NEXT: 10]]
// DYN: 5, 9]]
// DYN: 1, 0],
// DYN-NEXT: 0, 0]]
// NB-OUT: 11, 22, 33]]
// NB-ERR: mg.add: operand shapes differ at runtime in dimension 0
