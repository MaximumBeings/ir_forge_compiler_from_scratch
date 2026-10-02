// Optimization changes how fast the program runs, never what it computes. The same 3x5 @ 5x2 product (no dimension a multiple
// of the tile sizes) gives the same numbers at -O0, at -O2, and with the loops tiled by 2 and by 3 (dynamic shapes), and tiled by 2 (static).
// RUN: %mgc23 run %ex23/matmul_odd.mg -O0 | sed 's/base@ = 0x[0-9a-f]*//' > %t.o0
// RUN: %mgc23 run %ex23/matmul_odd.mg -O2 | sed 's/base@ = 0x[0-9a-f]*//' > %t.o2
// RUN: %mgc23 run %ex23/matmul_odd.mg -O2 --passes "--affine-loop-tile=tile-size=2" | sed 's/base@ = 0x[0-9a-f]*//' > %t.t2
// RUN: %mgc23 run %ex23/matmul_odd.mg -O3 --passes "--affine-loop-tile=tile-size=3" | sed 's/base@ = 0x[0-9a-f]*//' > %t.t3
// RUN: %mgc23 run %ex23/matmul_static.mg -O2 --passes "--affine-loop-tile=tile-size=2" | sed 's/base@ = 0x[0-9a-f]*//' > %t.ts
// RUN: diff %t.o0 %t.o2
// RUN: diff %t.o0 %t.t2
// RUN: diff %t.o0 %t.t3
// RUN: diff %t.o0 %t.ts
// RUN: %FileCheck %s --input-file=%t.o0
// CHECK: 12, 15],
// CHECK-NEXT: 32, 35],
// CHECK-NEXT: 52, 55]]
