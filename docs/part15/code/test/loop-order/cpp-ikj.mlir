// Chapter 21's whole C++ program (every elementwise result, matmul against a plain C++ loop, the dirty-heap check and the abort),
// run against a library compiled with the ikj loop order. The zero-fill matters just as much for ikj, and the dirty heap proves it.
// RUN: %mgc24 lib %cpp21b/ops.mg -o %t.d --matmul-order ikj
// RUN: %cxx -std=c++17 -Wall -Werror -I%t.d %cpp21b/app.cpp %t.d/ops.o -o %t.app
// RUN: %t.app | %FileCheck %s
// RUN: %not --crash %t.app mismatch > %t.o 2> %t.e
// RUN: %FileCheck %s --input-file=%t.e --check-prefix=ERR
// CHECK: matmul(a, b) (2x2):
// CHECK-NEXT: 58 64
// CHECK-NEXT: 139 154
// CHECK: gram(a) (2x2):
// CHECK-NEXT: 14 32
// CHECK-NEXT: 32 77
// CHECK: matmul matches a plain C++ triple loop: yes
// CHECK: dirty-heap matmul: 7 10 15 22
// CHECK: 7x5 @ 5x9 matches the plain loop: yes
// ERR: mg.matmul: inner dimensions differ at runtime
