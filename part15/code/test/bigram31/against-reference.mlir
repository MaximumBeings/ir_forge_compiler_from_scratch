// Chapter 31: the trainer agrees with an independent Python trainer at every checkpoint; the loss falls and never goes below the data's conditional
// entropy; the trained probabilities match the observed frequencies; the unseen token's row stays exactly zero; the hand-derived gradient matches
// finite differences; and weights of +-400 give no nan or inf. The script exits non-zero on any failure.
// RUN: env MG_OPT=%mg-opt python3 %ch31/check_bigram.py %ch31/mgc | %FileCheck %s
// CHECK: -- training against the independent Python trainer
// CHECK: ok   loss after 400 steps equals the reference
// CHECK: ok   weights after 400 steps equal the reference
// CHECK: -- the loss
// CHECK: ok   the loss is strictly decreasing at the checkpoints
// CHECK: ok   the loss never goes below the conditional entropy
// CHECK: -- what it learned
// CHECK: ok   token 3:
// CHECK: -- the unseen row
// CHECK: ok   so its probabilities are exactly uniform
// CHECK: -- the gradient against finite differences
// CHECK: ok   random weights #3: gradient and loss equal the reference
// CHECK: -- stress
// CHECK: ok   the gradient equals the reference
// CHECK: all checks pass
// CHECK-NOT: FAIL
