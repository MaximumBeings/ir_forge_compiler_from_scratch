// "Same arithmetic in the same order per element" is a claim about rounding, so test it with numbers that round: a 5x7 @ 7x4
// product of values that are not exactly representable, printed as hexadecimal floats (every bit), must be identical for ijk and ikj.
// RUN: %mgc24 lib %cpp21b/ops.mg -o %t.ijk --matmul-order ijk
// RUN: %mgc24 lib %cpp21b/ops.mg -o %t.ikj --matmul-order ikj
// RUN: %cxx -std=c++17 -Wall -Werror -I%t.ijk %S/../../../../part24/code/cpp/bits.cpp %t.ijk/ops.o -o %t.bits.ijk
// RUN: %cxx -std=c++17 -Wall -Werror -I%t.ikj %S/../../../../part24/code/cpp/bits.cpp %t.ikj/ops.o -o %t.bits.ikj
// RUN: %t.bits.ijk > %t.out.ijk
// RUN: %t.bits.ikj > %t.out.ikj
// RUN: diff %t.out.ijk %t.out.ikj
// RUN: %FileCheck %s --input-file=%t.out.ijk
// The product has 20 elements, each printed as a hexadecimal float such as 0x1.8p+2.
// CHECK-COUNT-20: 0x{{[0-9a-f.]+}}p{{[-+][0-9]+}}
