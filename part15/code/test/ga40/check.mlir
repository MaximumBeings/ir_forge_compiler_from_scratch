// Chapter 40: the GA-1 simulator and its schedules: every schedule gives exactly the triple loop's result (70 shape/schedule/buffering combinations); tiles moved equal the formulas;
// a six-instruction program takes the 84 cycles worked out by hand; the 4x4 double-buffered schedule is DMA-bound; an independent replay of the instruction trace finds no hazard.
// RUN: python3 %ch40/check_ga.py | %FileCheck %s
// CHECK: ok   all 70 schedule/shape/buffering combinations give exactly the triple loop's result
// CHECK: ok   tiles loaded and stored equal the formula in all 70 runs
// CHECK: ok   a six-instruction program takes 84 cycles
// CHECK: ok   4x4 double buffered on 64x64x64 is DMA-bound: 6400 cycles = 320 tiles x 20
// CHECK: ok   no read-before-write or write-before-read hazard in the traces of all 70 runs
// CHECK: all checks pass
// CHECK-NOT: FAIL
