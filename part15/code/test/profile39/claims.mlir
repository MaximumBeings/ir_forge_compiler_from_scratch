// Chapter 39: the claims about WHY SCFToControlFlow is super-linear, tested with valgrind's callgrind (instruction counts are exact and repeatable: this is not a timing test).
// In one function, the instructions in ilist_traits<Operation>::transferNodesFromList grow 4x per doubling of the loops (quadratic) while the whole program grows less than 2.3x;
// that function is called by Block::splitBlock; the same loops in functions of 100 grow 2x per doubling (linear); and after --mg-outline-loops neither appears.
// RUN: env MG_OPT=%mg-opt python3 %ch39/check_profile.py | %FileCheck %s
// CHECK: ok   one function: transferNodesFromList grows
// CHECK: ok   one function: the whole program grows
// CHECK: ok   transferNodesFromList is called by Block::splitBlock
// CHECK: ok   functions of 100 loops: transferNodesFromList grows
// CHECK: ok   after --mg-outline-loops: no transferNodesFromList and no splitBlock in the profile
// CHECK: all checks pass
// CHECK-NOT: FAIL
