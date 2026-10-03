// Chapter 34: each mistake in the layer-norm and residual examples is reported at compile time, with the file and line.
// RUN: %not %mgc32 run %ex34/errors/e1_scale_of_the_wrong_width.mg 2>&1 | %FileCheck %s --check-prefix=E1
// RUN: %not %mgc32 run %ex34/errors/e2_missing_argument.mg 2>&1 | %FileCheck %s --check-prefix=E2
// RUN: %not %mgc32 run %ex34/errors/e3_residual_shapes_differ.mg 2>&1 | %FileCheck %s --check-prefix=E3
// E1: e1_scale_of_the_wrong_width.mg:5: error: argument shape 1x3 does not fit parameter 1x4
// E2: e2_missing_argument.mg:5: error: ln_out takes 3 arguments, got 2
// E3: e3_residual_shapes_differ.mg:4: error: cannot add shapes 2x4 and 2x8: dimensions 4 and 8 differ and neither is 1
