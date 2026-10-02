// --matmul-order really reaches the pass: the kept affine IR of the same program differs in loop order.
// RUN: env MGC_KEEP=%t.a %mgc24 build %ex24/matmul_static.mg --matmul-order ijk -o %t.a.exe
// RUN: env MGC_KEEP=%t.b %mgc24 build %ex24/matmul_static.mg --matmul-order ikj -o %t.b.exe
// RUN: %FileCheck %s --input-file=%t.a/matmul_static.affine.mlir --check-prefix=IJK
// RUN: %FileCheck %s --input-file=%t.b/matmul_static.affine.mlir --check-prefix=IKJ
// matmul_static.mg is 3x5 @ 5x2: the accumulate nest bounds are 3,2,5 for ijk (reduction innermost) and 3,5,2 for ikj.
// IJK: affine.for %{{.*}} = 0 to 3 {
// IJK: affine.for %{{.*}} = 0 to 2 {
// IJK: affine.for %{{.*}} = 0 to 5 {
// IKJ: affine.for %{{.*}} = 0 to 3 {
// IKJ: affine.for %{{.*}} = 0 to 5 {
// IKJ: affine.for %{{.*}} = 0 to 2 {
