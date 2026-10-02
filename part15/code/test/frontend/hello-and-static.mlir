// Chapter 20: surface syntax -> native executable, static shapes.
// RUN: %mgc run %ex/01_hello.mg | %FileCheck %s --check-prefix=HELLO
// RUN: %mgc run %ex/02_add_transpose.mg | %FileCheck %s --check-prefix=ADDT
// HELLO: sizes = [2, 2]
// HELLO: 1, 2],
// HELLO-NEXT: 3, 4]]
// ADDT: sizes = [2, 3]
// ADDT: 11, 22, 33],
// ADDT-NEXT: 44, 55, 66]]
// ADDT: sizes = [3, 2]
// ADDT: 11, 44],
// ADDT-NEXT: 22, 55],
// ADDT-NEXT: 33, 66]]
// (the program under test is %ex/*.mg; this file only carries the RUN lines)
