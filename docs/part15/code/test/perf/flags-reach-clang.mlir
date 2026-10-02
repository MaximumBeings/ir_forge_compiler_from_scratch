// -O and MGC_CFLAGS must reach the final clang step. (They never change a program's RESULTS, so no run-time test can see them;
// instead MGC_CLANG=echo makes mgc print the clang command line it would run.)
// RUN: env MGC_CLANG=echo %mgc23 build %ex23/matmul_static.mg -O2 -o %t.x | %FileCheck %s --check-prefix=O2
// RUN: env MGC_CLANG=echo MGC_CFLAGS=-march=native %mgc23 build %ex23/matmul_static.mg -O3 -o %t.x | %FileCheck %s --check-prefix=O3
// RUN: env MGC_CLANG=echo %mgc23 build %ex23/matmul_static.mg -o %t.x | %FileCheck %s --check-prefix=NONE
// RUN: env MGC_CLANG=echo %mgc23 lib %ex23/../bench/matmul.mg -O2 -o %t.lib | %FileCheck %s --check-prefix=LIB
// O2: -O2 {{.*}}matmul_static.ll -o
// O3: -O3 -march=native {{.*}}matmul_static.ll -o
// NONE-NOT: -O
// NONE: matmul_static.ll -o
// LIB: -O2 -c {{.*}}matmul.ll -o
