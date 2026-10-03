// Chapter 33: the hand-derived backward pass equals an independent per-token Python gradient and finite differences of the loss for all 48 weights; the
// training run equals the reference at every checkpoint; the classifier gets all 24 training and 40 held-out sequences right, and 624 of all 625 possible
// sequences, the one miss being 4 4 4 4 (a label that never occurs in the data). The script exits non-zero on any failure.
// RUN: env MG_OPT=%mg-opt python3 %ch33/check_attention_training.py %ch33/../../part32/code/mgc | %FileCheck %s
// CHECK: -- the hand-derived backward pass
// CHECK: ok   starting weights #3: all 48 gradient entries agree with finite differences
// CHECK: -- training against the independent Python trainer
// CHECK: ok   step 200: loss 0.000522 and 24 of 24 correct equal the reference
// CHECK: -- learning
// CHECK: ok   all 40 held-out sequences are classified correctly
// CHECK: -- every one of the 625 possible sequences
// CHECK: ok   624 of 625 sequences are classified correctly
// CHECK: ok   the one wrong sequence is 4 4 4 4
// CHECK: -- attention scores
// CHECK: all checks pass
// CHECK-NOT: FAIL
