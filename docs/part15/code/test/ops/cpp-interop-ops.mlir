// The Chapter 21 operations from C++, compared against plain C++ loops.
// RUN: %mgc21 lib %cpp21/ops.mg -o %t.d
// RUN: %cxx -std=c++17 -Wall -Werror -I%t.d %cpp21/app.cpp %t.d/ops.o -o %t.app
// RUN: %t.app | %FileCheck %s
// RUN: %not --crash %t.app mismatch > %t.o 2> %t.e
// RUN: %FileCheck %s --input-file=%t.e --check-prefix=ERR
// CHECK: matmul(a, b) (2x2):
// CHECK-NEXT: 58 64
// CHECK-NEXT: 139 154
// CHECK: matmul matches a plain C++ triple loop: yes
// CHECK: 7x5 @ 5x9 matches the plain loop: yes
// ERR: mg.matmul: inner dimensions differ at runtime
