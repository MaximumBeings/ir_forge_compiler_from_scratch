// Chapter 43: mgc's new defaults (loops lowered last to first, loop nests of big functions outlined): the passes asked for, the same output as before on every third book example, small programs untouched,
// Chapter 35's training program outlined and running the same, and the run-time cost of the calls counted in exact instructions (about 30 each).
// RUN: env MG_OPT=%mg-opt python3 %ch43/check_defaults.py | %FileCheck %s
// CHECK: ok   default: outline + reverse; --no-outline, --no-reverse-loops, both, and the old spellings behave as named
// CHECK: ok   36 programs print the same with the defaults and with --no-outline --no-reverse-loops, 0 differ
// CHECK: ok   the self-attention example (under 32 nests per function) has no outlined function with the defaults
// CHECK: ok   Chapter 35's 10-step training program: 80 outlined functions by default, 0 with --no-outline
// CHECK: ok   and it prints the same 1842 characters either way
// CHECK: ok   Chapter 35's 10-step program: about 490 million instructions plain, 0.01% more outlined
// CHECK: ok   the 1,928 calls cost about 30 extra instructions each
// CHECK: all checks pass
// CHECK-NOT: FAIL
