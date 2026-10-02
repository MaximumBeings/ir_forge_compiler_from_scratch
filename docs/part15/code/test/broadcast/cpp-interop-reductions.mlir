// C++ calls relu, reductions, a layer and centering, and each result matches plain C++ loops.
// RUN: %mgc22 lib %cpp22/ops.mg -o %t.d
// RUN: %cxx -std=c++17 -Wall -Werror -I%t.d %cpp22/app.cpp %t.d/ops.o -o %t.app
// RUN: %t.app | %FileCheck %s
// CHECK: relu_m 7x5{{ +}}matches
// CHECK: row_sums 7x5{{ +}}matches
// CHECK: col_maxes 7x5{{ +}}matches
// CHECK: layer: relu(x @ w + bias), 4x6 by 6x3{{ +}}matches
// CHECK: center: subtract each column's mean, 5x4{{ +}}matches
