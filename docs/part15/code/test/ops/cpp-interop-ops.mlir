// The Chapter 21 operations from C++, compared against plain C++ loops.
// RUN: %mgc21 lib %cpp21/ops.mg -o %t.d
// RUN: %cxx -std=c++17 -Wall -Werror -I%t.d %cpp21/app.cpp %t.d/ops.o -o %t.app
// RUN: %t.app | %FileCheck %s
// RUN: %not --crash %t.app mismatch > %t.o 2> %t.e
// RUN: %FileCheck %s --input-file=%t.e --check-prefix=ERR
// Every function's result is checked against exact expected values (each is computed by hand from a = [[1,2,3],[4,5,6]],
// b = [[7,8],[9,10],[11,12]], c = [[6,5,4],[3,2,1]]).
// CHECK: sub(a, c) (2x3):
// CHECK-NEXT: -5 -3 -1
// CHECK-NEXT: 1 3 5
// CHECK: hadamard(a, c) (2x3):
// CHECK-NEXT: 6 10 12
// CHECK-NEXT: 12 10 6
// CHECK: divide(a, c) (2x3):
// CHECK-NEXT: 0.166667 0.4 0.75
// CHECK-NEXT: 1.33333 2.5 6
// CHECK: matmul(a, b) (2x2):
// CHECK-NEXT: 58 64
// CHECK-NEXT: 139 154
// CHECK: gram(a) (2x2):
// CHECK-NEXT: 14 32
// CHECK-NEXT: 32 77
// CHECK: affine(a) (2x3):
// CHECK-NEXT: 3 5 7
// CHECK-NEXT: 9 11 13
// CHECK: matmul matches a plain C++ triple loop: yes
// CHECK: dirty-heap matmul: 7 10 15 22
// CHECK: 7x5 @ 5x9 matches the plain loop: yes
// ERR: mg.matmul: inner dimensions differ at runtime
