// The run-time shape check names the operation: sub, mul and div abort on a mismatch exactly as add does,
// with the message on stderr and nothing on stdout. (Only add's check was tested before this file.)
// RUN: %not --crash %mgc21 run %ex21/15_elementwise_mismatch.mg > %t.sub.out 2> %t.sub.err
// RUN: %not --crash %mgc21 run %ex21/15b_mul_mismatch.mg > %t.mul.out 2> %t.mul.err
// RUN: %not --crash %mgc21 run %ex21/15c_div_mismatch.mg > %t.div.out 2> %t.div.err
// RUN: %FileCheck %s --input-file=%t.sub.err --check-prefix=SUB
// RUN: %FileCheck %s --input-file=%t.mul.err --check-prefix=MUL
// RUN: %FileCheck %s --input-file=%t.div.err --check-prefix=DIV
// RUN: %FileCheck %s --input-file=%t.sub.out --check-prefix=EMPTY --allow-empty
// RUN: %FileCheck %s --input-file=%t.mul.out --check-prefix=EMPTY --allow-empty
// RUN: %FileCheck %s --input-file=%t.div.out --check-prefix=EMPTY --allow-empty
// SUB: mg.sub: operand shapes differ at runtime in dimension 0
// MUL: mg.mul: operand shapes differ at runtime in dimension 0
// DIV: mg.div: operand shapes differ at runtime in dimension 0
// EMPTY-NOT: sizes
