// Chapter 32: the examples compile and run and print the values the page shows. 01 was worked out by hand (see the comments in the file); the training runs
// (02 to 06) are checked against the independent Python trainer in against-reference.mlir; here the numbers the page quotes are pinned.
// RUN: %mgc32 run %ex32/01_ge.mg | %FileCheck %s --check-prefix=X1
// RUN: %mgc32 run %ex32/02_train_and_validate.mg | %FileCheck %s --check-prefix=X2
// RUN: %mgc32 run %ex32/03_weight_decay.mg | %FileCheck %s --check-prefix=X3
// RUN: %mgc32 run %ex32/04_too_strong.mg | %FileCheck %s --check-prefix=X4
// RUN: %mgc32 run %ex32/05_generate.mg | %FileCheck %s --check-prefix=X5
// RUN: %mgc32 run %ex32/06_a_tie.mg | %FileCheck %s --check-prefix=X6
// X1: 0, 1, 1],
// X1-NEXT: 1, 1, 1]]
// X1: 0, 1, 1],
// X1-NEXT: 0, 0, 1]]
// X1: 0, 1, 0],
// X1-NEXT: 1, 0, 0]]
// X1: 1, 1, 0]]
// X1: 0, 1, 0]]
// X2: 1.60944]]
// X2: 1.60944]]
// X2: 0.832556]]
// X2: 1.48224]]
// X2: 0.41714]]
// X2: 4.03635]]
// X2: 8.07078],
// X2-NEXT: 0.00252321],
// X2-NEXT: 0.288306],
// X2-NEXT: 7.78379]]
// X3: 0.960112]]
// X3: 1.47494]]
// X3: -0.426541, 1.07857, 0.201049, -0.426541, -0.426541],
// X3-NEXT: -0.366977, -0.366977, 0.809691, 0.29124, -0.366977],
// X3-NEXT: 1.04192, -0.26048, -0.26048, -0.26048, -0.26048],
// X3-NEXT: 0.641953, -0.160488, -0.160488, -0.160488, -0.160488],
// X3-NEXT: 0, 0, 0, 0, 0]]
// X3: 2.03837],
// X3-NEXT: 1.02709],
// X3-NEXT: 0.733227],
// X3-NEXT: 2.10107]]
// X4: e+58
// X5: 0]]
// X5: 1]]
// X5: 2]]
// X5: 0]]
// X5: 1]]
// X5: 2]]
// X6: 4]]
// X6: 10]]
// X6: 0]]
