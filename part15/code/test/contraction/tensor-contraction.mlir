// Chapter 27: tensor contractions computed as a transpose, a reshape, ONE Mountain Goat matrix product, and a reshape back, and compared
// with the definition (direct sums over every index). Built twice (optimized with the ikj loop order, and with the plain defaults);
// both builds must pass every check and print identical output.
// RUN: %mgc24 lib %cpp27/contract.mg -o %t.fast -O2 --matmul-order ikj
// RUN: %mgc24 lib %cpp27/contract.mg -o %t.plain
// RUN: %cxx -std=c++17 -O2 -Wall -Wextra -Werror -I%t.fast -I%cpp27 %cpp27/contract_demo.cpp %t.fast/contract.o -o %t.demo.fast
// RUN: %cxx -std=c++17 -O2 -Wall -Wextra -Werror -I%t.plain -I%cpp27 %cpp27/contract_demo.cpp %t.plain/contract.o -o %t.demo.plain
// RUN: %t.demo.fast | %FileCheck %s
// RUN: %t.demo.plain | %FileCheck %s
// RUN: %t.demo.fast > %t.out.fast
// RUN: %t.demo.plain > %t.out.plain
// RUN: diff %t.out.fast %t.out.plain
// The appendix's two worked examples, with its numpy-checked values:
// CHECK: 1. Matrix multiply
// CHECK: 1.00 2.00 4.00 5.00
// CHECK-NEXT: 3.00 4.00 10.00 11.00
// CHECK-NEXT: 5.00 6.00 16.00 17.00
// CHECK: equals the appendix's numpy-checked values: yes
// CHECK: as matrices: 2x12 times 12x5  ->  120 multiply-adds (the appendix's formula T x product of contracted sizes: 10 x 12 = 120)
// CHECK: output shape [2,5]
// CHECK: 10.00 5.00 0.00 -5.00 -10.00
// CHECK-NEXT: 2.00 1.00 0.00 -1.00 -2.00
// CHECK: equals the appendix's numpy.tensordot values: yes
// Nine contractions against the definition, bit for bit:
// CHECK: matrix product {{.*}} -> [3,4] {{ *}}matches the definition bit for bit: yes
// CHECK: double contraction {{.*}} -> [2,5] {{ *}}matches the definition bit for bit: yes
// CHECK: contracted axis in the FRONT of A {{.*}} -> [3,4,5] {{ *}}matches the definition bit for bit: yes
// CHECK: contracted axes listed in reverse order {{.*}} -> [2,5] {{ *}}matches the definition bit for bit: yes
// CHECK: contracted axes in the middle of both {{.*}} -> [5,4,6] {{ *}}matches the definition bit for bit: yes
// CHECK: vector times matrix {{.*}} -> [6] {{ *}}matches the definition bit for bit: yes
// CHECK: dot product (every axis contracted) {{.*}} -> [] {{ *}}matches the definition bit for bit: yes
// CHECK: outer product (no contracted axis) {{.*}} -> [3,4] {{ *}}matches the definition bit for bit: yes
// CHECK: rank 3 x rank 3, one shared axis {{.*}} -> [3,4,2,3] {{ *}}matches the definition bit for bit: yes
// The axis checks, with their exact messages:
// CHECK: rejected, as it should be: "contract: mismatched dimension on contracted axis pair 0 (A.shape[1]=2 vs B.shape[0]=4)"
// CHECK: also rejected: "contract: axes_a and axes_b must have the same length"
// CHECK: also rejected: "contract: axis 5 is out of range for A"
// CHECK: also rejected: "contract: axis 1 is listed twice for A"
// CHECK: All checks passed.
