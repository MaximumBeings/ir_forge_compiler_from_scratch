// Chapter 45: autograd.py, reverse-mode automatic differentiation written as a source-to-source transformation of Mountain Goat programs: every rule against finite differences of an independent
// evaluation (112 elements), ties, the hand-derived backward passes of Chapters 33, 34 and 35 reproduced (the transformer block: 16 gradient matrices), ten training steps with the generated
// gradients giving Chapter 33's loss curve, and clean refusals.
// RUN: env MG_OPT=%mg-opt python3 %ch45/check_autograd.py | %FileCheck %s
// CHECK: ok   all 10 programs: the generated gradients match finite differences in every one of 112 matrix elements
// CHECK: ok   col_sum(row_max(m)) for m = {{.*}}the gradient is
// CHECK: ok   Chapter 33's attention classifier: loss and 4 gradient matrices (48 elements) equal the hand-derived ones
// CHECK: ok   Chapter 34's layer normalisation: loss and 1 gradient matrices (4 elements) equal the hand-derived ones
// CHECK: ok   Chapter 35's transformer block: loss and 16 gradient matrices (648 elements) equal the hand-derived ones
// CHECK: ok   10 gradient-descent steps (lr 3.0) on Chapter 33's classifier with the GENERATED gradients: loss 1.60134 1.51356 0.625597 0.273815 after 0, 1, 5, 10 steps
// CHECK: ok   a non-1x1 loss, an unknown name, an unused matrix and a loss that is flat in a matrix are refused with a message
// CHECK: ok   a program that is not rank 2 (Chapter 28's) is refused with a message: autograd: rank 3 tensors are not supported
// CHECK: all checks pass
// CHECK-NOT: FAIL
