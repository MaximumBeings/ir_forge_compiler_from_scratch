// Chapter 31: the examples compile and run and print the values the page shows. 01 to 03 were worked out by hand (see the comments in the files);
// 04 (the 400-step training run) is checked against the independent Python trainer in against-reference.mlir.
// RUN: %mgc31 run %ex31/01_log.mg | %FileCheck %s --check-prefix=X1
// RUN: %mgc31 run %ex31/02_cross_entropy.mg | %FileCheck %s --check-prefix=X2
// RUN: %mgc31 run %ex31/03_one_gradient_step.mg | %FileCheck %s --check-prefix=X3
// RUN: %mgc31 run %ex31/04_training.mg | %FileCheck %s --check-prefix=X4
// X1: 0, 1, 2.30259],
// X1-NEXT: -0.693147, 4.60517, -6.90776]]
// X1: 1, 2, 10],
// X1-NEXT: 0.5, 100, 0.001]]
// X1: -inf]]
// X1: {{-?}}nan]]
// X1: 3.73767, 1.38629]]
// X1: 3.73767, 1.38629]]
// X2: 1.09861],
// X2-NEXT: 0.0202027],
// X2-NEXT: 4.60517],
// X2-NEXT: 0.693147]]
// X2: 1.60428]]
// X3: 0.693147]]
// X3: 0.125, -0.125],
// X3-NEXT: -0.125, 0.125]]
// X3: -0.125, 0.125],
// X3-NEXT: 0.125, -0.125]]
// X3: 0.638439]]
// X4: 1.60944]]
// X4: 0.992623]]
// X4: 0.845013]]
// X4: 0.718402]]
// X4: 0.666934]]
// X4: 0.634284]]
// X4: 0.623229]]
// X4: 0.617695]]
// X4: 0.614931]]
// X4: 0.613551]]
// X4: -2.81579, 4.91782, 3.52955, -2.81579, -2.81579],
// X4: 0, 0, 0, 0, 0]]
// X4: 0.000350059, 0.799476, 0.199474, 0.000350059, 0.000350059],
// X4-NEXT: 0.000654832, 0.000654832, 0.499564, 0.249563, 0.249563],
// X4-NEXT: 0.665791, 0.000584647, 0.000584647, 0.332455, 0.000584647],
// X4-NEXT: 0.998244, 0.000439023, 0.000439023, 0.000439023, 0.000439023],
// X4-NEXT: 0.2, 0.2, 0.2, 0.2, 0.2]]
