#!/usr/bin/env python3
"""Writes the Chapter 32 example programs. The training programs are generated from generalize.mg.defs.in (so a page example cannot drift from the definitions)."""
import os
import generalize_lib as G
here = os.path.join(os.path.dirname(os.path.abspath(__file__)), "examples")
def write(name, text): open(os.path.join(here, name), "w").write(text)
write("01_ge.mg", """# ge(a, b) compares: 1 where a >= b and 0 where it is not, element by element, with the same broadcasting as + - * /.
print ge([[1, 5, 3], [2, 2, 9]], [[2, 2, 2], [2, 2, 2]])       # which entries are at least 2?
print ge([[1, 5, 3], [2, 2, 9]], [[2], [9]])                    # a 2x1 column is stretched across the columns: row 0 against 2, row 1 against 9
# the one-hot row of the largest entry: compare a row with its own maximum (row_max gives a 2x1 column)
let scores = [[0.2, 0.7, 0.1], [0.5, 0.1, 0.4]]
print ge(scores, row_max(scores))
# a tie gives several 1s: both 0.5s reach the maximum
print ge([[0.5, 0.5, 0.0]], row_max([[0.5, 0.5, 0.0]]))
# a comparison against a number: write the number as a 1x1 matrix
print ge([[0.2, 0.7, 0.1]], [[0.5]])
""")
write("02_train_and_validate.mg", G.train_program(0))
write("03_weight_decay.mg", G.train_program(0.1))
write("04_too_strong.mg", G.train_program(G.UNSTABLE))
write("05_generate.mg", G.generate_program(0.1, start=0, n=8))
write("06_a_tie.mg", G.generate_program(0.1, start=4, n=2))
write("errors/e1_ge_of_a_scalar.mg", "# ge compares two matrices. A bare number in the source is a compile-time scalar; write a threshold as a 1x1 matrix.\nprint ge([[1, 2]], 1)\n")
write("errors/e2_ge_shapes_differ.mg", "# The shapes must agree or broadcast: 2x3 and 3x2 do not.\nprint ge([[1, 2, 3], [4, 5, 6]], [[1, 2], [3, 4], [5, 6]])\n")
write("errors/e3_held_out_pairs_to_the_training_loss.mg", f"""# The held-out data have 4 pairs and the training loss was written for 10. Passing one where the other belongs is a shape error, caught when compiling.
{[l for l in G.defs(0.1).split(chr(10)) if l.startswith('def log_softmax10')][0]}
{[l for l in G.defs(0.1).split(chr(10)) if l.startswith('def train_loss')][0]}
let w = [[0, 0, 0, 0, 0], [0, 0, 0, 0, 0], [0, 0, 0, 0, 0], [0, 0, 0, 0, 0], [0, 0, 0, 0, 0]]
let xv = {G.lit(G.XV)}
let yv = {G.lit(G.YV)}
print train_loss(w, xv, yv)
""")
