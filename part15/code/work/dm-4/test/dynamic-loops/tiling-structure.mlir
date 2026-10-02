// Chapter 17: the tiled dynamic nest steps the tile loops by 4 and clips each point loop with min(...), which is how
// a remainder tile is handled. Two nests (add, transpose), so everything below happens twice.
// RUN: %mg-opt %inputs/chain.mlir --convert-mg-to-affine | %mg-opt --affine-loop-tile="tile-size=4" | %FileCheck %s
// CHECK: #map1 = affine_map<(d0, d1) -> (d1 + 4, d0)>
// CHECK-COUNT-2: affine.for %{{.*}} = #map(%{{.*}}) to #map(%{{.*}}) step 4 {
// CHECK: affine.for %{{.*}} = #map(%{{.*}}) to min #map1(%{{.*}}, %{{.*}}) {
// CHECK: affine.for %{{.*}} = #map(%{{.*}}) to min #map1(%{{.*}}, %{{.*}}) {
// CHECK-COUNT-2: affine.for %{{.*}} = #map(%{{.*}}) to #map(%{{.*}}) step 4 {
// CHECK: to min #map1
