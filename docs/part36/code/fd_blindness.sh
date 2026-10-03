#!/bin/sh
# Two of the mutants in model_mutation.py were caught only by the comparison with the reference in the lean mode (finite differences for six weights). Run them through the
# FULL gradient check (finite differences for the largest-gradient weight of every one of the 36 matrices) to see whether finite differences would have caught them.
# Output: fd_blindness_out.txt
cd "$(dirname "$0")"
echo "mutant 1: softmax backward misses the row-sum correction in head 2 of block 2 only"
MG_MUTANT_OLD=" - row_sum(a2_b2_g * da2_b2_g))" MG_MUTANT_NEW=")" python3 check_lm2.py 2>&1 | sed -n 1,5p | cut -c1-220
echo
echo "mutant 2: dk forgets to transpose ds in head 2 of block 1 only"
MG_MUTANT_OLD="transpose(ds2_b1_g) @ q2_b1_g" MG_MUTANT_NEW="ds2_b1_g @ q2_b1_g" python3 check_lm2.py 2>&1 | sed -n 1,5p | cut -c1-220
