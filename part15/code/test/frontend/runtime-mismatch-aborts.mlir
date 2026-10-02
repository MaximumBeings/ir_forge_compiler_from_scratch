// Chapter 20: a runtime shape mismatch aborts, and the message is on stderr (Chapter 19's pass is in the driver).
// RUN: %not --crash %mgc run %ex/04_mismatch.mg 2> %t.err
// RUN: %FileCheck %s --input-file=%t.err --check-prefix=E4
// RUN: %mgc run %ex/10_mixed.mg > %t.out 2> %t.err10 || true
// RUN: %FileCheck %s --input-file=%t.out --check-prefix=OUT10
// RUN: %FileCheck %s --input-file=%t.err10 --check-prefix=E10
// E4: mg.add: operand shapes differ at runtime in dimension 0
// OUT10: 11, 12],
// OUT10-NEXT: 13, 14],
// OUT10-NEXT: 15, 16]]
// E10: mg.add: operand shapes differ at runtime in dimension 0
