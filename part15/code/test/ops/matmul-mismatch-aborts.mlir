// Inner dimensions that disagree at run time: abort, message on stderr, nothing on stdout.
// RUN: %not --crash %mgc21 run %ex21/12_matmul_mismatch.mg > %t.out 2> %t.err
// RUN: %FileCheck %s --input-file=%t.err
// RUN: %FileCheck %s --input-file=%t.out --check-prefix=NOOUT --allow-empty
// CHECK: mg.matmul: inner dimensions differ at runtime
// NOOUT-NOT: sizes
