// Front-end errors for the new operators.
// RUN: %not %mgfront21 %ex21/errors/bad_matmul.mg 2>&1 | %FileCheck %s --check-prefix=MM
// RUN: %not %mgfront21 %ex21/errors/bad_scalar.mg 2>&1 | %FileCheck %s --check-prefix=SC
// MM: bad_matmul.mg:3: error: cannot multiply (matmul) shapes 2x3 and 2x3: inner dimensions differ
// SC: bad_scalar.mg:4: error: '@' (matrix product) needs two matrices, not a scalar
