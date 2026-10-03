// Chapter 35: the two small examples were worked out by hand (see the comments in the files); the ten-step training run is checked against the independent
// Python implementation in against-reference.mlir, and the numbers the page quotes from it are pinned here. (The 200-step example takes about eight minutes and
// is run by run_examples.sh and check_lm.py --full, not by this test.)
// RUN: %mgc32 run %ex35/01_stacked_causal_mask.mg | %FileCheck %s --check-prefix=X1
// RUN: %mgc32 run %ex35/02_masked_cross_entropy.mg | %FileCheck %s --check-prefix=X2
// RUN: %mgc32 run %ex35/03_train_10_steps.mg | %FileCheck %s --check-prefix=X3
// X1: 1,   0,   0,   0,   0,   0],
// X1: 0.5,   0.5,   0,   0,   0,   0],
// X1: 0.333333,   0.333333,   0.333333,   0,   0,   0],
// X1: 0,   0,   0,   1,   0,   0],
// X1: 0,   0,   0,   0.5,   0.5,   0],
// X1: 0,   0,   0,   0.333333,   0.333333,   0.333333]]
// X2: 1.25311]]
// X2: 0,   0,   0],
// X2: 0.166667,   -0.333333,   0.166667],
// X2: 0,   0,   0],
// X2: 0.0450153,   0.33262,   -0.377636]]
// X3: 1.42919]]
// X3: 20]]
// X3: 1.28756]]
// X3: 29]]
// X3: 0.965858]]
// X3: 39]]
