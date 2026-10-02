// Chapter 20: compiled Mountain Goat functions called from C++ through the generated header.
// RUN: %mgc lib %cpp/kernels.mg -o %t.d
// RUN: %cxx -std=c++17 -Wall -Werror -I%t.d %cpp/app.cpp %t.d/kernels.o -o %t.app
// RUN: %t.app | %FileCheck %s
// RUN: %not --crash %t.app mismatch > %t.mm.out 2> %t.mm.err
// RUN: %FileCheck %s --input-file=%t.mm.err --check-prefix=ERR
// CHECK: add(a, b) (2x3):
// CHECK-NEXT: 11 22 33
// CHECK-NEXT: 44 55 66
// CHECK: add_t(a, b) (3x2):
// CHECK-NEXT: 11 44
// CHECK: scale2(a) (2x3):
// CHECK-NEXT: 4 8 12
// CHECK: rot(a) (3x2):
// CHECK: caught: rot: argument 'a' has the wrong shape
// ERR: mg.add: operand shapes differ at runtime in dimension 0
