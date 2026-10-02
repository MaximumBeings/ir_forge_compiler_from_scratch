// Regression test for a bug the language tour found: '3e2' was copied into the MLIR, which only accepts '3.0e2'.
// Scientific and decimal spellings, and a large scalar exponent, must reach the compiled program intact.
// RUN: %mgfront22 %tour/02_literals.mg | %FileCheck %s --check-prefix=MLIR
// RUN: %mgc22 run %tour/02_literals.mg | %FileCheck %s --check-prefix=SMALL
// RUN: echo 'let a = [[1e16, 3e2, 2.5e-3]]' > %t.mg
// RUN: echo 'print a * 1e20' >> %t.mg
// RUN: %mgfront22 %t.mg | %FileCheck %s --check-prefix=BIGMLIR
// RUN: %mgc22 run %t.mg | %FileCheck %s --check-prefix=BIG
// MLIR: mg.constant dense<{{\[\[}}1.5, -2.0, 300.0]]> : tensor<1x3xf64>
// SMALL: 1.5, -2, 300]]
// BIGMLIR: dense<{{\[\[}}1.0e+16, 300.0, 0.0025]]>
// BIGMLIR: value = 1.0e+20 : f64
// BIG: 1e+36, 3e+22, 2.5e+17]]
