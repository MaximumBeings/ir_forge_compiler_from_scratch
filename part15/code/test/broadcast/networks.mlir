// A layer and a two-layer network, composed from every operation so far.
// RUN: %mgc22 run %ex22/07_mlp_layer.mg | %FileCheck %s --check-prefix=LAYER
// RUN: %mgc22 run %ex22/08_two_layers.mg | %FileCheck %s --check-prefix=NET
// LAYER: sizes = [2, 2]
// LAYER: 4.5, 0],
// LAYER-NEXT: 0, 0]]
// NET: sizes = [2, 1]
// NET: 4],
// NET-NEXT: 0]]
