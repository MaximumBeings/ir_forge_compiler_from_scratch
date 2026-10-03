// Chapter 41: the GA-1 back end: 61 programs print the CPU's matrices (27 rejected for dynamic shapes or rank); all 8 option combinations, other tile sizes and scratchpads are right;
// pinned cycle counts for cse / fusion / double buffering; decode and prefill take the same cycles (weights streamed once); unsupported programs are refused with a message.
// RUN: env MG_OPT=%mg-opt python3 %ch41/check_backend.py | %FileCheck %s
// CHECK: ok   61 programs print the same matrices as the CPU path, 0 differ
// CHECK: ok   the 27 rejected programs are rejected for dynamic shapes or rank, nothing else
// CHECK: ok   all 8 combinations of cse / fusion / double buffering give the CPU's answer on 3 programs
// CHECK: ok   tiles of 4, 8 and 16 and scratchpads of 24 and 64 slots all give the CPU's answer
// CHECK: ok   softmax (stable): 1854 cycles with nothing, 1194 with cse, 804 with cse and fusion
// CHECK: ok   8-token block: 7484 cycles with nothing, 3564 with all three options
// CHECK: ok   fusion turns 22 kernels into 13
// CHECK: ok   1, 2, 4 and 8 tokens all take 14400 cycles
// CHECK: ok   useful matrix-unit utilization is proportional to the tokens: 1: 3.6%, 2: 7.1%, 4: 14.2%, 8: 28.4%
// CHECK: ok   dynamic shapes and rank 3 are refused with a message
// CHECK: all checks pass
// CHECK-NOT: FAIL
