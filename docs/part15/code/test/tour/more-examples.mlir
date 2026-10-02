// The language tour's extra examples (17-22) print exactly the values the page shows; each was worked out by hand first (see the comments in the files).
// RUN: %mgc22 run %tour/17_more_literals.mg | %FileCheck %s --check-prefix=M17
// RUN: %mgc22 run %tour/18_let_chains.mg | %FileCheck %s --check-prefix=M18
// RUN: %mgc22 run %tour/19_function_composition.mg | %FileCheck %s --check-prefix=M19
// RUN: %mgc22 run %tour/20_one_function_many_shapes.mg | %FileCheck %s --check-prefix=M20
// RUN: %mgc22 run %tour/21_scalars_on_either_side.mg | %FileCheck %s --check-prefix=M21
// RUN: %mgc22 run %tour/22_precedence.mg | %FileCheck %s --check-prefix=M22
// M17: sizes = [1, 1]
// M17: 5]]
// M17: 0.25, -0.5, 0.001]]
// M17: sizes = [1, 6]
// M17: sizes = [6, 1]
// M17: 6]]
// M17: sizes = [6, 1]
// M17: 6]]
// M17: 1, 2],
// M17-NEXT: 3, 4]]
// M18: 5]]
// M18: -3, -1, -1, -1, 0, 0, 2, 4]]
// M18: 4]]
// M18: 16]]
// M19: 3, 4],
// M19-NEXT: 6, 9]]
// M19: 33, 48],
// M19-NEXT: 72, 105]]
// M19: -14, -20],
// M19-NEXT: -30, -44]]
// M20: sizes = [1, 1]
// M20: 5]]
// M20: sizes = [3, 3]
// M20: 1, 0, 1],
// M20-NEXT: 0, 1, 1],
// M20-NEXT: 1, 1, 2]]
// M20: 5, 7, 9]]
// M20: 10]]
// M21: 0, 1],
// M21-NEXT: 3, 7]]
// M21: 9, 8],
// M21-NEXT: 6, 2]]
// M21: 0.5, 1],
// M21-NEXT: 2, 4]]
// M21: 16, 8],
// M21-NEXT: 4, 2]]
// M21: 3, 5],
// M21-NEXT: 9, 17]]
// M21: 3, 2],
// M21-NEXT: {{-?}}0, -4]]
// M22: 2, 2],
// M22-NEXT: 3, 12]]
// M22: 2, 0],
// M22-NEXT: 0, 16]]
// M22: 2, 6],
// M22-NEXT: 6, 12]]
// M22: 8, 14],
// M22-NEXT: 18, 30]]
// M22: -1, -2],
// M22-NEXT: -3, -4]]
// M22: -1, {{-?}}0],
// M22-NEXT: {{-?}}0, -8]]
// M22: 13, 18],
// M22-NEXT: 27, 38]]
