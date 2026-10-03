// Chapter 33: the small examples were worked out by hand (see the comments in the files); the training run is checked against the independent Python
// implementation in against-reference.mlir, and the numbers the page quotes from it are pinned here.
// RUN: %mgc32 run %ex33/01_attention_by_hand.mg | %FileCheck %s --check-prefix=X1
// RUN: %mgc32 run %ex33/02_softmax_backward.mg | %FileCheck %s --check-prefix=X2
// RUN: %mgc32 run %ex33/03_train.mg | %FileCheck %s --check-prefix=X3
// X1: 1.41421],
// X1-NEXT: 1.06066],
// X1-NEXT: 0.707107],
// X1-NEXT: 0]]
// X1: 0.410109, 0.287974, 0.202212, 0.0997045]]
// X1: 5.64067, 2.12183]]
// X2: 0.309696, -0.12646, -0.183235]]
// X2: 0.309696]]
// X2: -0.126462]]
// X2: -0.183235]]
// X3: 1.60134]]
// X3: 0]]
// X3: 1.51356]]
// X3: 18]]
// X3: 0.625597]]
// X3: 21]]
// X3: 0.273815]]
// X3: 21]]
// X3: 0.0903657]]
// X3: 24]]
// X3: 0.0098207]]
// X3: 24]]
// X3: 0.00168072]]
// X3: 24]]
// X3: 0.000522397]]
// X3: 24]]
