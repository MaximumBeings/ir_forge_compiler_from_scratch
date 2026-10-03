// Chapter 42: lowering structured control flow last to first (--mg-scf-to-cf-reverse): the same IR as --convert-scf-to-cf on 107 book programs and on 3000 loops, correct on if/while/nested loops
// (the lowered edge-case program prints 10, 1000, 128, 153, 10153), the same output on real programs, and a linear instruction count (exact, from callgrind) where convert-scf-to-cf is quadratic.
// RUN: env MG_OPT=%mg-opt python3 %ch42/check_reverse.py | %FileCheck %s
// CHECK: ok   {{[0-9]+}} programs lower to byte-identical IR
// CHECK: ok   loop with result, scf.if, scf.while, nested loops: the same text from both lowerings
// CHECK: ok   the lowered program prints 10, 1000, 128, 153, 10153
// CHECK: ok   three programs print identical output
// CHECK: ok   one function of 3000 loops: byte-identical IR from both lowerings
// CHECK: ok   convert-scf-to-cf: transferNodesFromList grows x3.97 and x3.98 per doubling
// CHECK: ok   last to first: transferNodesFromList grows x2.00 and x2.00 per doubling
// CHECK: ok   last to first: block splitting is 0.0% of the instructions at 2000 loops
// CHECK: all checks pass
// CHECK-NOT: FAIL
