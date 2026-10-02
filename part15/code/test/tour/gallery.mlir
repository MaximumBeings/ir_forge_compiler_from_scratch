// The language tour's gallery (examples 7-16 and errors e10-e12) prints exactly the values the page shows.
// Values were also checked by hand on the page (e.g. Markov: 5/6 + (1/6)*0.4^8 = 0.833443).
// Example 16 aborts BY DESIGN (a '?' dimension never stretches): the message and the failing status are the expected result.
// RUN: %mgc22 run %tour/07_shapes_flow.mg | %FileCheck %s --check-prefix=G7
// RUN: %mgc22 run %tour/08_column_statistics.mg | %FileCheck %s --check-prefix=G8
// RUN: %mgc22 run %tour/09_polynomial.mg | %FileCheck %s --check-prefix=G9
// RUN: %mgc22 run %tour/10_rotation.mg | %FileCheck %s --check-prefix=G10
// RUN: %mgc22 run %tour/11_markov_chain.mg | %FileCheck %s --check-prefix=G11
// RUN: %mgc22 run %tour/12_graph_walks.mg | %FileCheck %s --check-prefix=G12
// RUN: %mgc22 run %tour/13_blur.mg | %FileCheck %s --check-prefix=G13
// RUN: %mgc22 run %tour/14_affine_layers.mg | %FileCheck %s --check-prefix=G14
// RUN: %mgc22 run %tour/15_batches.mg | %FileCheck %s --check-prefix=G15
// RUN: %not --crash %mgc22 run %tour/16_dynamic_bias_gotcha.mg > %t.out 2> %t.err
// RUN: %FileCheck %s --check-prefix=G16 --input-file=%t.out
// RUN: %FileCheck %s --check-prefix=G16E --input-file=%t.err
// RUN: %not %mgc22 run %tour/errors/e10_star_vs_at.mg 2>&1 | %FileCheck %s --check-prefix=E10
// RUN: %not %mgc22 run %tour/errors/e11_at_needs_inner_match.mg 2>&1 | %FileCheck %s --check-prefix=E11
// RUN: %mgc22 run %tour/errors/e12_transpose_fixes_it.mg | %FileCheck %s --check-prefix=E12
// G7: sizes = [2, 4]
// G7: 4, 5, 4, 5],
// G7-NEXT: 10, 11, 13, 14]]
// G7: sizes = [4, 2]
// G7: 4, 10],
// G7-NEXT: 5, 11],
// G7-NEXT: 4, 13],
// G7-NEXT: 5, 14]]
// G7: sizes = [1, 4]
// G7: 14, 16, 17, 19]]
// G7: sizes = [2, 1]
// G7: 18],
// G7-NEXT: 48]]
// G8: sizes = [1, 2]
// G8: 2.5, 25]]
// G8: sizes = [4, 2]
// G8: -1.5, -15],
// G8-NEXT: -0.5, -5],
// G8-NEXT: 0.5, 5],
// G8-NEXT: 1.5, 15]]
// G8: sizes = [1, 2]
// G8: 1.25, 125]]
// G9: sizes = [3, 1]
// G9: 6],
// G9-NEXT: 17],
// G9-NEXT: 34]]
// G10: sizes = [2, 3]
// G10: 0, -1, 0],
// G10-NEXT: 1, 0, -1]]
// G10: -1, 0, 1],
// G10-NEXT: 0, -1, 0]]
// G10: -1, -0, 1],
// G10-NEXT: -0, -1, -0]]
// G11: 0.9, 0.1]]
// G11: 0.86, 0.14]]
// G11: 0.833443, 0.166557]]
// G12: sizes = [4, 4]
// G12: 0, 0, 1, 2],
// G12-NEXT: 1, 0, 0, 1],
// G12-NEXT: 1, 0, 0, 0],
// G12-NEXT: 0, 1, 1, 0]]
// G12: 2, 0, 0, 1],
// G12-NEXT: 1, 1, 1, 0],
// G12-NEXT: 0, 1, 1, 0],
// G12-NEXT: 0, 0, 1, 2]]
// G13: sizes = [3, 5]
// G13: 0, 2.25, 4.5, 2.25, 0],
// G13-NEXT: 2.25, 6.75, 9, 6.75, 2.25],
// G13-NEXT: 6.75, 11.25, 9, 11.25, 6.75]]
// G14: 3],
// G14-NEXT: 7]]
// G14: 7],
// G14-NEXT: 22]]
// G15: sizes = [1, 2]
// G15: 1, 2]]
// G15: sizes = [3, 2]
// G15: 1, 2],
// G15-NEXT: 2, 4],
// G15-NEXT: 3, 6]]
// G15: sizes = [3, 2]
// G15: 11, 22],
// G15-NEXT: 12, 24],
// G15-NEXT: 13, 26]]
// G16: sizes = [1, 2]
// G16: 11, 22]]
// G16E: mg.add: operand shapes differ at runtime in dimension 0
// E10: e10_star_vs_at.mg:4: error: cannot multiply shapes 2x3 and 3x2: dimensions 2 and 3 differ and neither is 1
// E11: e11_at_needs_inner_match.mg:3: error: cannot multiply (matmul) shapes 2x3 and 2x3: inner dimensions differ
// E12: sizes = [2, 2]
// E12: 14, 32],
// E12-NEXT: 32, 77]]
