// Chapter 35: the language model's hand-derived backward pass (stacked sequences, causal mask, layer norms, relu feed-forward, residuals) equals an independent
// per-position Python gradient for all 16 weight matrices at three starting points, and two weights of every matrix agree with finite differences; ten training
// steps equal the reference at every checkpoint, as do the held-out loss and the per-chunk counts and the attention pattern. The script exits non-zero on any
// failure (about half a minute). The 200-step run of the page is `check_lm.py --full` (about eight minutes) and is not part of this test.
// RUN: env MG_OPT=%mg-opt python3 %ch35/check_lm.py %ch35/../../part32/code/mgc | %FileCheck %s
// CHECK: -- the hand-derived backward pass
// CHECK: ok   starting weights #1: the loss and all 16 gradient matrices equal the reference
// CHECK: ok   starting weights #1: 32 weights (two of every matrix) agree with finite differences
// CHECK: ok   starting weights #3: the loss and all 16 gradient matrices equal the reference
// CHECK: -- training 10 steps
// CHECK: ok   step 10
// CHECK: ok   the 16 held-out sequences
// CHECK: ok   the attention pattern of the first training sequence equals the reference's
// CHECK: ok   every attention row sums to 1
// CHECK: all checks pass
// CHECK-NOT: FAIL
