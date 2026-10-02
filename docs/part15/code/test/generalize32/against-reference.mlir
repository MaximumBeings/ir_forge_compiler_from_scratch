// Chapter 32: the programs agree with an independent Python trainer; the model overfits without weight decay (held-out loss rises while training loss
// falls) because of held-out pairs the training pairs never showed; weight decay lowers the held-out loss at the price of a higher training loss; too
// strong a penalty for the learning rate diverges identically in both; the penalised gradient matches finite differences; greedy generation equals the
// reference chain. The script exits non-zero on any failure.
// RUN: env MG_OPT=%mg-opt python3 %ch32/check_generalize.py %ch32/mgc | %FileCheck %s
// CHECK: -- training and held-out loss against the independent Python trainer
// CHECK: ok   strength 0.1: final weights and probabilities equal the reference
// CHECK: -- a strength that is too large
// CHECK: ok   the loss grows without bound
// CHECK: -- overfitting without weight decay
// CHECK: ok   held-out loss RISES at every checkpoint from step 5 on
// CHECK: -- why
// CHECK: ok   the unseen pairs carry more than 90% of the held-out loss
// CHECK: -- weight decay
// CHECK: ok   the strength with the lowest held-out loss is 0.1 for both
// CHECK: -- the gradient with weight decay
// CHECK: ok   strength 0.1, random weights #2
// CHECK: -- greedy generation
// CHECK: ok   starting from token 3
// CHECK: all checks pass
// CHECK-NOT: FAIL
