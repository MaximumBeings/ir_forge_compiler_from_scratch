// --passes really reaches mg-opt: without it the matmul has 5 loops (a 2-deep zero-fill and a 3-deep accumulate); with tile-size=2
// each nest gains one tile loop per dimension (4 + 6 = 10 loops), and the point loops stop at min(tile end, size).
// (`mgc build` must exit with status 0 on success; it used to exit 1, a bug this test would have caught.)
// RUN: env MGC_KEEP=%t.plain %mgc23 build %ex23/matmul_static.mg -o %t.plain.exe
// RUN: env MGC_KEEP=%t.tiled %mgc23 build %ex23/matmul_static.mg --passes "--affine-loop-tile=tile-size=2" -o %t.tiled.exe
// RUN: grep -c "affine.for" %t.plain/matmul_static.affine.mlir | %FileCheck %s --check-prefix=PLAIN
// RUN: grep -c "affine.for" %t.tiled/matmul_static.affine.mlir | %FileCheck %s --check-prefix=TILED
// RUN: %FileCheck %s --input-file=%t.tiled/matmul_static.affine.mlir --check-prefix=MIN
// PLAIN: 5
// TILED: 10
// MIN: affine.for {{.*}} to min
