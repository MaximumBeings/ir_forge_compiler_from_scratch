// Chapter 17: unrolling by 2 splits the inner loop into a main loop that stops at (n floordiv 2) * 2 and steps by 2,
// plus an epilogue loop for the leftover iteration. Seen for both nests.
// RUN: %mg-opt %inputs/chain.mlir --convert-mg-to-affine | %mg-opt --affine-loop-unroll="unroll-factor=4" | %FileCheck %s
// CHECK: #map1 = affine_map<()[s0] -> ((s0 floordiv 2) * 2)>
// CHECK: affine.for %{{.*}} = #map(%{{.*}}) to #map1()[%{{.*}}] step 2 {
// CHECK: arith.addf
// CHECK: arith.addf
// CHECK: affine.for %{{.*}} = #map1()[%{{.*}}] to #map(%{{.*}}) {
// CHECK: affine.for %{{.*}} = #map(%{{.*}}) to #map1()[%{{.*}}] step 2 {
// CHECK: affine.for %{{.*}} = #map1()[%{{.*}}] to #map(%{{.*}}) {
