// Properties that must hold whatever the lowering does: centered columns sum to 0; normalized rows sum to 1.
// RUN: %mgc22 run %ex22/05_center_columns.mg | %FileCheck %s --check-prefix=CENTER
// RUN: %mgc22 run %ex22/06_normalize_rows.mg | %FileCheck %s --check-prefix=NORM
// CENTER: -1, -20],
// CENTER-NEXT: 0, -10],
// CENTER-NEXT: 1, 30]]
// CENTER: sizes = [1, 2]
// CENTER: 0, 0]]
// NORM: 0.25, 0.25, 0.5],
// NORM-NEXT: 0.5, 0, 0.5]]
// NORM: sizes = [2, 1]
// NORM: 1],
// NORM-NEXT: 1]]
