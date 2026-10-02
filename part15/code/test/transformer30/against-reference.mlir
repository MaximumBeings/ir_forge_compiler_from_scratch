// Chapter 30: the transformer agrees with an independent Python implementation at every stage (relative tolerance 1e-5, mgc prints six digits), for
// several weight sets; and it has the properties a transformer must have: probabilities sum to 1, causality, permutation equivariance, normalised layer
// norm, and no nan or inf when the weights are large enough to overflow a naive softmax. The script exits non-zero on any failure.
// RUN: env MG_OPT=%mg-opt python3 %ch30/check_transformer.py %ch30/mgc | %FileCheck %s
// CHECK: -- every stage against the reference
// CHECK: ok   weights 7, tokens [2, 0, 4, 1]: probs equals the reference
// CHECK: -- stress
// CHECK: ok   large weights: no nan and no inf anywhere in the output
// CHECK: ok   large weights: probs equals the reference
// CHECK: -- causality
// CHECK: ok   changing token 1: row 1 of the probabilities does change
// CHECK: ok   without the mask, changing the last token DOES change row 0
// CHECK: -- permutation equivariance
// CHECK: ok   with positions added, the same permutation is NOT a permutation of the outputs
// CHECK: -- layer norm
// CHECK: ok   random 4x4 #3: the constant row becomes exactly 0
// CHECK: all checks pass
// CHECK-NOT: FAIL
