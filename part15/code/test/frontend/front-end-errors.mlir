// Chapter 20: mistakes are reported by the front end, with file:line, before any MLIR is produced.
// RUN: %not %mgfront %ex/errors/bad_shape.mg 2>&1 | %FileCheck %s --check-prefix=SHAPE
// RUN: %not %mgfront %ex/errors/bad_syntax.mg 2>&1 | %FileCheck %s --check-prefix=SYN
// RUN: %not %mgfront %ex/errors/bad_shape.mg 2>/dev/null | %not %FileCheck %s --check-prefix=NOMLIR --allow-empty
// SHAPE: bad_shape.mg:2: error: cannot add shapes 1x2 and 2x1
// SYN: bad_syntax.mg:3: error: a statement must start with 'let', 'print' or 'def', not 'show'
// NOMLIR: {{.}}
