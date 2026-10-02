// Both loop orders (and each tiled, at sizes that are not tile multiples) print identical output for the same product,
// which is the hand-computed 12 15 / 32 35 / 52 55; static and dynamic shapes.
// RUN: %mgc24 run %ex24/matmul_odd.mg --matmul-order ijk | sed 's/base@ = 0x[0-9a-f]*//' > %t.ijk
// RUN: %mgc24 run %ex24/matmul_odd.mg --matmul-order ikj | sed 's/base@ = 0x[0-9a-f]*//' > %t.ikj
// RUN: %mgc24 run %ex24/matmul_odd.mg -O2 --matmul-order ikj --passes "--affine-loop-tile=tile-size=2" | sed 's/base@ = 0x[0-9a-f]*//' > %t.ikj2
// RUN: %mgc24 run %ex24/matmul_odd.mg -O2 --matmul-order ikj --passes "--affine-loop-tile=tile-size=3" | sed 's/base@ = 0x[0-9a-f]*//' > %t.ikj3
// RUN: %mgc24 run %ex24/matmul_static.mg --matmul-order ikj | sed 's/base@ = 0x[0-9a-f]*//' > %t.ikjs
// RUN: diff %t.ijk %t.ikj
// RUN: diff %t.ijk %t.ikj2
// RUN: diff %t.ijk %t.ikj3
// RUN: diff %t.ijk %t.ikjs
// RUN: %FileCheck %s --input-file=%t.ikj
// CHECK: 12, 15],
// CHECK-NEXT: 32, 35],
// CHECK-NEXT: 52, 55]]
