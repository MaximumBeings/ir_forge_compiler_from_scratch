// Chapter 34: both backward passes (attention only, and attention with layer norm, relu feed-forward and residual) equal an independent per-example Python
// gradient and finite differences for EVERY weight (36 and 120), for three starting points each; both training runs equal the reference at every checkpoint;
// and the experiment's findings hold: model A cannot fit its data and gets at most 70 of the 81 possible sequences right, model B fits all 54 training
// sequences and gets 80 of 81 right, the one miss being 0 0 0 0 (not in the training data). The script exits non-zero on any failure (about two minutes).
// RUN: env MG_OPT=%mg-opt python3 %ch34/check_ffn.py %ch34/../../part32/code/mgc | %FileCheck %s
// CHECK: -- the hand-derived backward passes
// CHECK: ok   model A, starting weights #3: all 36 weights agree with finite differences
// CHECK: ok   model B, starting weights #3: all 120 weights agree with finite differences
// CHECK: -- training model A
// CHECK: ok   model A, step 600
// CHECK: -- training model B
// CHECK: ok   model B, step 600
// CHECK: -- the experiment
// CHECK: ok   model A cannot fit its own training data
// CHECK: ok   model B fits all 54 training sequences
// CHECK: ok   the one sequence model B gets wrong is 0 0 0 0
// CHECK: all checks pass
// CHECK-NOT: FAIL
