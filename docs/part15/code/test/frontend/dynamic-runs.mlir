// Chapter 20: dynamic shapes through the driver; one compiled function, several sizes.
// RUN: %mgc run %ex/03_dynamic.mg | %FileCheck %s --check-prefix=DYN
// RUN: %mgc run %ex/09_vectors.mg | %FileCheck %s --check-prefix=VEC
// DYN: sizes = [3, 2]
// DYN: 11, 44],
// DYN-NEXT: 22, 55],
// DYN-NEXT: 33, 66]]
// DYN: sizes = [1, 3]
// DYN: 1.5, 2.5, 3.5]]
// VEC: sizes = [4, 1]
// VEC: 11],
// VEC-NEXT: 12],
// VEC-NEXT: 13],
// VEC-NEXT: 14]]
// VEC: sizes = [1, 4]
// VEC: 6, 7, 8, 9]]
