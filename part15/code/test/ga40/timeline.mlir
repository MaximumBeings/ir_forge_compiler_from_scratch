// Chapter 40: the text timeline of a 32x32x32 product as one 2x2 block: single buffered 1696 cycles, double buffered 1600 (both move 80 tiles).
// RUN: python3 %ch40/timeline.py | %FileCheck %s
// CHECK: 2 x 2 block of C, single buffered: 1696 cycles, 80 tiles moved
// CHECK: 2 x 2 block of C, double buffered: 1600 cycles, 80 tiles moved
