// Each error example on the tour page produces exactly the message the page shows, with its line number.
// RUN: %not %mgfront21 %tour/errors/e1_bad_statement.mg 2>&1 | %FileCheck %s --check-prefix=E1
// RUN: %not %mgfront21 %tour/errors/e2_unknown_name.mg 2>&1 | %FileCheck %s --check-prefix=E2
// RUN: %not %mgfront21 %tour/errors/e3_shape_mismatch.mg 2>&1 | %FileCheck %s --check-prefix=E3
// RUN: %not %mgfront21 %tour/errors/e4_function_order.mg 2>&1 | %FileCheck %s --check-prefix=E4
// RUN: %not %mgfront21 %tour/errors/e5_arity.mg 2>&1 | %FileCheck %s --check-prefix=E5
// RUN: %not %mgfront21 %tour/errors/e6_scalar_print.mg 2>&1 | %FileCheck %s --check-prefix=E6
// RUN: %not %mgfront21 %tour/errors/e7_param_shape.mg 2>&1 | %FileCheck %s --check-prefix=E7
// RUN: %not %mgfront21 %tour/errors/e8_zero_dimension.mg 2>&1 | %FileCheck %s --check-prefix=E8
// RUN: %not %mgfront21 %tour/errors/e9_let_in_def.mg 2>&1 | %FileCheck %s --check-prefix=E9
// E1: e1_bad_statement.mg:2: error: a statement must start with 'let', 'print' or 'def', not 'show'
// E2: e2_unknown_name.mg:2: error: unknown name 'b'
// E3: e3_shape_mismatch.mg:3: error: cannot add shapes 1x2 and 2x1
// E4: e4_function_order.mg:2: error: unknown function 'f'
// E5: e5_arity.mg:2: error: f takes 1 arguments, got 2
// E6: e6_scalar_print.mg:2: error: print needs a matrix; a scalar has no shape to print
// E7: e7_param_shape.mg:2: error: argument shape 1x3 does not fit parameter 2x2
// E8: e8_zero_dimension.mg:1: error: bad dimension '0': use a positive integer or '?'
// E9: e9_let_in_def.mg:1: error: expected an expression, found the end of the line
