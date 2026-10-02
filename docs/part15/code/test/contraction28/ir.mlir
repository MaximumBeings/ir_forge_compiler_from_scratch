// Chapter 28: what contract(...) turns into. Example 4 puts the contracted axis FIRST in A, so A is permuted (free axes first), flattened to
// a matrix, multiplied, and the product reshaped to the 3x4x5 result: permute, reshape, matmul, reshape, all of them Mountain Goat operations.
// RUN: %mgc28 mlir %ex28/04_axis_at_the_front.mg | %FileCheck %s
// CHECK: mg.permute {{.*}}permutation = array<i64: 1, 2, 0>{{.*}} : tensor<2x3x4xf64> -> tensor<3x4x2xf64>
// CHECK: mg.reshape {{.*}} : tensor<3x4x2xf64> -> tensor<12x2xf64>
// CHECK: mg.matmul {{.*}} : tensor<12x2xf64>, tensor<2x5xf64> -> tensor<12x5xf64>
// CHECK: mg.reshape {{.*}} : tensor<12x5xf64> -> tensor<3x4x5xf64>
// A contraction that needs no permutation moves no data: example 3's operands already have the free axis first (A) and the contracted axes first (B),
// and example 2 (a plain matrix product) needs neither a reshape nor a permute.
// RUN: %mgc28 mlir %ex28/03_double_contraction.mg | %FileCheck %s --check-prefix=NOPERM
// RUN: %mgc28 mlir %ex28/02_matmul_is_a_contraction.mg | %FileCheck %s --check-prefix=PLAIN
// NOPERM-NOT: mg.permute
// NOPERM: mg.matmul {{.*}} : tensor<2x12xf64>, tensor<12x5xf64> -> tensor<2x5xf64>
// PLAIN-NOT: mg.permute
// PLAIN-NOT: mg.reshape
// PLAIN: mg.matmul {{.*}} : tensor<3x2xf64>, tensor<2x4xf64> -> tensor<3x4xf64>
