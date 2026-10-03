// Chapter 44: --mg-set-fastmath and mgc --fast-math: the flags on every floating-point arith operation (reassoc, contract by default), nothing changed when off, the ijk dot-product loop vectorized only
// with the flags, the same printed numbers on the book's examples, and the negative control (nnan changes an answer: ge(p, p) for NaN p prints 1).
// RUN: env MG_OPT=%mg-opt python3 %ch44/check_fastmath.py | %FileCheck %s
// CHECK: ok   all 4 floating-point operations get fastmath<reassoc,contract>
// CHECK: ok   flags=reassoc,nsz gives exactly those flags
// CHECK: ok   default: 18 fadd/fsub/fmul/fdiv in the self-attention example, none with a flag
// CHECK: ok   --fast-math: all 18 carry reassoc contract
// CHECK: ok   --fast-math=reassoc: all 18 carry reassoc and nothing else
// CHECK: ok   ijk product, static and dynamic sizes: not vectorized
// CHECK: ok   {{[0-9]+}} programs (every sixth example) print the same at -O2 with --fast-math, 0 differ
// CHECK: ok   ge(p, p) for a NaN p at -O2: plain {{.*}} with nnan {{.*}} (the last is WRONG
// CHECK: all checks pass
// CHECK-NOT: FAIL
