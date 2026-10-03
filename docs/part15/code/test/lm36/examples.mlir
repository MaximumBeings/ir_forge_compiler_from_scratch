// Chapter 36: the two small examples were worked out by hand (see the comments in the files); the ten-step training run is checked against the independent Python
// implementation in against-reference.mlir, and the numbers the page quotes from it are pinned here. (The 200-step example takes about 40 minutes and is run by
// run_examples.sh and check_lm2.py --full, not by this test.)
// RUN: %mgc32 run %ex36/01_two_paths_add.mg | %FileCheck %s --check-prefix=X1
// RUN: %mgc32 run %ex36/02_two_blocks_chain.mg | %FileCheck %s --check-prefix=X2
// RUN: %mgc32 run %ex36/03_train_10_steps.mg | %FileCheck %s --check-prefix=X3
// X1: 1,   6],
// X1: 3,   3]]
// X1: 1]]
// X1: 6]]
// X1: 3]]
// X1: 3]]
// X2: 1.125,   1.125,   1.125]]
// X2: 1.125,   0,   0]]
// X3: 1.59625]]
// X3: 10]]
// X3: 1.35291]]
// X3: 20]]
// X3: 1.03453]]
// X3: 39]]
// X3: 1.54478]]
// X3: 16]]
// X3: 12]]
// X3: 33]]
// X3: 28]]
// X3: 20]]
