// A linear layer and a Gram matrix: several ops composed in one expression.
// RUN: %mgc21 run %ex21/07_linear_layer.mg | %FileCheck %s --check-prefix=LAYER
// RUN: %mgc21 run %ex21/08_gram.mg | %FileCheck %s --check-prefix=GRAM
// LAYER: sizes = [2, 2]
// LAYER: 4.5, 5.5],
// LAYER-NEXT: 10.5, 11.5]]
// GRAM: 14, 32],
// GRAM-NEXT: 32, 77]]
// GRAM: sizes = [3, 3]
// GRAM: 17, 22, 27],
// GRAM-NEXT: 22, 29, 36],
// GRAM-NEXT: 27, 36, 45]]
