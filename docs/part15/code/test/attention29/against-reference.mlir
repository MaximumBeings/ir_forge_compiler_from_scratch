// Chapter 29: softmax and attention agree with an independent Python implementation (relative tolerance 1e-5, because mgc prints six significant
// digits), rows sum to 1, softmax is shift invariant, and causal weights above the diagonal are exactly 0. The script exits non-zero on any failure.
// RUN: env MG_OPT=%mg-opt python3 %ch29/check_attention.py | %FileCheck %s
// CHECK: -- softmax against the reference
// CHECK: ok   softmax 2x6, scores in [480, 500]: equals the reference
// CHECK: ok   softmax 2x6, scores in [-500, -480]: equals the reference
// CHECK: ok   softmax 2x6, scores in [-1500, -1000]: equals the reference
// CHECK: -- attention
// CHECK: ok   causal attention n=5 d=3: weights above the diagonal are exactly 0, rows sum to 1
// CHECK: all checks pass
// CHECK-NOT: FAIL
