// Chapter 30: the examples compile and run and print the values the page shows. 01 and 02 were also worked out by hand (see the comments in the files);
// 03 and 04 are checked against the independent Python implementation in against-reference.mlir. 04 changes only the LAST token: rows 0 to 2 of every
// output of 03 and 04 are identical (the causal mask), and only row 3 differs.
// RUN: %mgc30 run %ex30/01_layer_norm.mg | %FileCheck %s --check-prefix=X1
// RUN: %mgc30 run %ex30/02_feed_forward.mg | %FileCheck %s --check-prefix=X2
// RUN: %mgc30 run %ex30/03_tiny_transformer.mg | %FileCheck %s --check-prefix=X3
// RUN: %mgc30 run %ex30/04_last_token_changed.mg | %FileCheck %s --check-prefix=X4
// X1: -1.34164, -0.447212, 0.447212, 1.34164],
// X1-NEXT: 0, 0, 0, 0],
// X1-NEXT: -1.4142, 0, 1.4142, 0],
// X1-NEXT: -0.57735, -0.57735, -0.57735, 1.73205]]
// X1: 2.31673, 4.10558, 5.89442, 7.68327],
// X1-NEXT: 5, 5, 5, 5],
// X1-NEXT: 2.1716, 5, 7.8284, 5],
// X1-NEXT: 3.8453, 3.8453, 3.8453, 8.4641]]
// X2: 1, -2, 0, 3],
// X2-NEXT: -1, 1, -1, 1],
// X2-NEXT: 0, 0, 0, 0],
// X2-NEXT: 5, -5, 2, -2]]
// X2: 0, -2, 0, 2],
// X2-NEXT: -1, 0, -1, 0],
// X2-NEXT: 0, 0, 0, 0],
// X2-NEXT: 4, -5, 1, -2]]
// X3: 0.9, 0.34, 0.4, 0.45],
// X3: 0.353842, 0.387514, -0.308814, -0.435457],
// X3: 0.649067, 1.91099, -1.84495, -0.288202],
// X3: 0.296546, 0.108577, 0.108446, 0.250679, 0.235753],
// X3-NEXT: 0.221851, 0.126921, 0.0812285, 0.211973, 0.358027],
// X3-NEXT: 0.146912, 0.185544, 0.263232, 0.12015, 0.284162],
// X3-NEXT: 0.12842, 0.201212, 0.198259, 0.116907, 0.355202]]
// X4: 0.9, 0.34, 0.4, 0.45],
// X4: 0.353842, 0.387514, -0.308814, -0.435457],
// X4: 0.649067, 1.91099, -1.84495, -0.288202],
// X4: 0.296546, 0.108577, 0.108446, 0.250679, 0.235753],
// X4-NEXT: 0.221851, 0.126921, 0.0812285, 0.211973, 0.358027],
// X4-NEXT: 0.146912, 0.185544, 0.263232, 0.12015, 0.284162],
// X4-NEXT: 0.119444, 0.193318, 0.137116, 0.117316, 0.432807]]
