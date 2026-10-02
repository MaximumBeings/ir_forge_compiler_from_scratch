// Chapter 26: linear regression by gradient descent. The gradient, update and loss run in compiled Mountain Goat; the loop, the data
// and the checks are in the C++ driver, which prints "yes" or "NO" for each property. The trainer is built twice: optimized with
// the ikj matmul loop order, and with the plain defaults (-O0, ijk). Both must pass every check: the compiler settings change the speed, not the answer.
// RUN: %mgc24 lib %cpp26/gd.mg -o %t.fast -O2 --matmul-order ikj
// RUN: %mgc24 lib %cpp26/gd.mg -o %t.plain
// RUN: %cxx -std=c++17 -O2 -Wall -Werror -I%t.fast %cpp26/train.cpp %t.fast/gd.o -o %t.train.fast
// RUN: %cxx -std=c++17 -O2 -Wall -Werror -I%t.plain %cpp26/train.cpp %t.plain/gd.o -o %t.train.plain
// RUN: %t.train.fast | %FileCheck %s
// RUN: %t.train.plain | %FileCheck %s
// RUN: %t.train.fast > %t.out.fast
// RUN: %t.train.plain > %t.out.plain
// RUN: diff %t.out.fast %t.out.plain
// CHECK: A. noise-free data
// CHECK: loss fell at every step: yes
// CHECK: parameters recovered to within 1e-6 of the truth: yes
// CHECK: matches the plain C++ gradient descent to within 1e-9: yes
// CHECK: the first 5 steps match plain C++ step for step to within 1e-12: yes
// CHECK: the compiled loss equals a plain C++ loss (at the start and the end): yes
// CHECK: B. noisy data
// CHECK: gradient descent matches the exact least-squares answer to within 1e-6: yes
// CHECK: the compiled loss equals a plain C++ loss on the noisy data: yes
// CHECK: closer to the exact answer than to the truth: yes
// CHECK: C. noise-free data, learning rate 1.20 (too large)
// CHECK: the loss grew instead of shrinking: yes
