// Chapter 46: Hessian-vector products by differentiating the generated backward pass (hvp.py): eight small programs times three directions against four-point finite differences of the loss,
// symmetry of the Hessian, the first print equal to the directional derivative, and Chapter 33's classifier (15 parameters).
// RUN: env MG_OPT=%mg-opt python3 %ch46/check_hvp.py | %FileCheck %s
// CHECK: ok   all 8 programs x 3 directions: H v from the compiled double-differentiated program equals H (four-point finite differences) times v, in every one of 156 elements
// CHECK: ok   symmetry: w' (H v) = v' (H w) for every program (computed with two compiled programs)
// CHECK: ok   the program's first print, sum(g * v), equals the finite-difference directional derivative of the loss along v
// CHECK: ok   H v for Chapter 33's wo0 (3x5) equals the finite-difference Hessian times v to 1e-4 (step 1e-3 limits that reference)
// CHECK: ok   wrt a and b together: both blocks of H (v_a, v_b), cross terms included, equal the finite-difference Hessian over all 12 parameters times (v_a, v_b)
// CHECK: ok   a missing direction matrix is refused with a message
// CHECK: all checks pass
// CHECK-NOT: FAIL
