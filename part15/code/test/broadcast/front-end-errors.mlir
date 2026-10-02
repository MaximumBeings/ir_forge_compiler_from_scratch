// Front-end errors for broadcasting and mean.
// RUN: %not %mgfront22 %ex22/errors/bad_broadcast.mg 2>&1 | %FileCheck %s --check-prefix=BAD
// RUN: %not %mgfront22 %ex22/errors/dynamic_mean.mg 2>&1 | %FileCheck %s --check-prefix=MEAN
// BAD: bad_broadcast.mg:2: error: cannot add shapes 2x3 and 3x2: dimensions 2 and 3 differ and neither is 1
// MEAN: dynamic_mean.mg:2: error: row_mean needs a static size along the averaged axis, not '?'
