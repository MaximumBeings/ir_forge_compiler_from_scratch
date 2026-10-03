// Chapter 38: what --outline does to the IR, counted from the affine IR that mgc keeps. Each example has loop nests directly in `main`.
// 01: 35 nests become 35 calls of FOUR functions; no loop is left in main (every affine.for is inside an outlined function: four nests of two loops each = 8).
// 02: 39 nests become 39 calls of ONE function (2 loops). 03: the dynamic-shape function's 39 nests become 39 calls of ONE function, which takes the run-time sizes as arguments.
// 04: two nests, below the threshold of 32: nothing is outlined, and the two nests stay in main (4 loops).
// RUN: env MGC_KEEP=%t.1 %mgc38 build %ex38/01_four_distinct_nests.mg --outline -o %t.1.exe
// RUN: env MGC_KEEP=%t.2 %mgc38 build %ex38/02_one_nest_forty_times.mg --outline -o %t.2.exe
// RUN: env MGC_KEEP=%t.3 %mgc38 build %ex38/03_dynamic_shapes.mg --outline -o %t.3.exe
// RUN: env MGC_KEEP=%t.4 %mgc38 build %ex38/04_below_threshold.mg --outline -o %t.4.exe
// RUN: sh -c 'f=%t.1/01_four_distinct_nests.affine.mlir; test $(grep -c "func.func private @mg_outlined" $f) -eq 4 && test $(grep -c "call @mg_outlined" $f) -eq 35 && test $(grep -c "affine.for" $f) -eq 8'
// RUN: sh -c 'f=%t.2/02_one_nest_forty_times.affine.mlir; test $(grep -c "func.func private @mg_outlined" $f) -eq 1 && test $(grep -c "call @mg_outlined" $f) -eq 39 && test $(grep -c "affine.for" $f) -eq 2'
// RUN: sh -c 'f=%t.3/03_dynamic_shapes.affine.mlir; test $(grep -c "func.func private @mg_outlined" $f) -eq 2 && test $(grep -c "call @mg_outlined" $f) -eq 39'
// RUN: sh -c 'f=%t.4/04_below_threshold.affine.mlir; test $(grep -c "mg_outlined" $f) -eq 0 && test $(grep -c "affine.for" $f) -eq 4'
// RUN: %FileCheck %s --input-file=%t.3/03_dynamic_shapes.affine.mlir
// The dynamic-shape functions receive the two run-time sizes (index values computed outside the nest) as arguments after the memrefs they read and write: the first nest (`a + a`) has two memrefs, every later one (`sum + a`) three.
// CHECK: func.func private @mg_outlined_0(%arg0: memref<?x?xf64>, %arg1: memref<?x?xf64>, %arg2: index, %arg3: index)
// CHECK: func.func private @mg_outlined_1(%arg0: memref<?x?xf64>, %arg1: memref<?x?xf64>, %arg2: memref<?x?xf64>, %arg3: index, %arg4: index)
