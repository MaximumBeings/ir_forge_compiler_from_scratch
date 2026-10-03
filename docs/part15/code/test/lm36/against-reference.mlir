// Chapter 36: the language model's hand-derived backward pass (two blocks, two heads each, stacked sequences, causal mask, layer norms, relu feed-forward networks,
// residuals) equals an independent per-position Python gradient for all 36 weight matrices at three starting points, and the largest-gradient weight of every matrix
// agrees with finite differences; ten training steps equal the reference at every checkpoint, as do the held-out loss, the per-chunk counts and all four attention
// patterns. The script exits non-zero on any failure (about a minute). The 200-step run of the page is `check_lm2.py --full` (about 40 minutes) and is not part of this test.
// RUN: env MG_OPT=%mg-opt python3 %ch36/check_lm2.py %ch36/../../part32/code/mgc | %FileCheck %s
// CHECK: -- the hand-derived backward pass
// CHECK: ok   starting weights #1: the loss and all 36 gradient matrices equal the reference
// CHECK: ok   starting weights #1: 36 weights
// CHECK: ok   starting weights #3: the loss and all 36 gradient matrices equal the reference
// CHECK: -- training 10 steps
// CHECK: ok   step 10
// CHECK: ok   the 16 held-out sequences
// CHECK: ok   four attention patterns were printed
// CHECK: ok   the four attention patterns of the first training sequence equal the reference's
// CHECK: ok   every attention row of every head sums to 1
// CHECK: all checks pass
// CHECK-NOT: FAIL
