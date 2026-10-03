#!/usr/bin/env python3
"""Writes the Chapter 36 example programs. The training programs are generated from lm2_lib (so a page example cannot drift from the definitions)."""
import os
import lm2_lib as M
here = os.path.join(os.path.dirname(os.path.abspath(__file__)), "examples")
def write(name, text): open(os.path.join(here, name), "w").write(text)

write("01_two_paths_add.mg", """# Fan-out: one matrix u feeds TWO different maps (as a block's normalised input feeds two attention heads). If the loss is
#     L = sum(r1 * (u @ wa)) + sum(r2 * (u @ wb))
# for fixed matrices r1, r2, then u affects L along two routes, and the gradient with respect to u is the SUM of the gradients along them:
#     dL/du = r1 @ transpose(wa) + r2 @ transpose(wb)
# (the same rule that makes a residual connection add, and that adds the three routes q, k, v into one layer norm in Chapter 35).
# The first matrix is that formula. The next four are two entries of u, found by brute force: nudge the entry by 0.01 up and down and watch L change.
def loss(u: tensor[2x2], wa: tensor[2x2], wb: tensor[2x2], r1: tensor[2x2], r2: tensor[2x2]) = col_sum(row_sum(r1 * (u @ wa))) + col_sum(row_sum(r2 * (u @ wb)))
let u = [[1, 2], [3, 4]]
let wa = [[1, 0], [2, 1]]
let wb = [[0, 3], [1, 1]]
let r1 = [[1, 2], [0, 1]]
let r2 = [[2, 0], [1, 1]]
print r1 @ transpose(wa) + r2 @ transpose(wb)
print (loss(u + [[0.01, 0], [0, 0]], wa, wb, r1, r2) - loss(u - [[0.01, 0], [0, 0]], wa, wb, r1, r2)) / 0.02
print (loss(u + [[0, 0.01], [0, 0]], wa, wb, r1, r2) - loss(u - [[0, 0.01], [0, 0]], wa, wb, r1, r2)) / 0.02
print (loss(u + [[0, 0], [0.01, 0]], wa, wb, r1, r2) - loss(u - [[0, 0], [0.01, 0]], wa, wb, r1, r2)) / 0.02
print (loss(u + [[0, 0], [0, 0.01]], wa, wb, r1, r2) - loss(u - [[0, 0], [0, 0.01]], wa, wb, r1, r2)) / 0.02
# The four brute-force numbers are the four entries of the formula's matrix, read in the order (0,0), (0,1), (1,0), (1,1). Using only one of the two terms would be wrong
# for every entry.
""")
write("02_two_blocks_chain.mg", """# Two blocks in a row, each with a residual connection: x1 = x + f1(x), x2 = x1 + f2(x1). Here f1 and f2 are just a scale (x * w1 and x1 * w2), so every
# quantity is a 1 x 3 row and the answer can be checked by hand. By the chain rule dx2/dx = (1 + w1) * (1 + w2): the identity path of each residual lets the gradient
# through unchanged, and each block adds its own contribution. The backward pass works from the last block to the first, one residual at a time:
#     d1 = d2 * (1 + w2)          (gradient with respect to x1)
#     d0 = d1 * (1 + w1)          (gradient with respect to x)
# Here w1 = 0.5 and w2 = -0.25, so the factor is 1.5 * 0.75 = 1.125. The brute-force line nudges x by 0.01 and compares.
def forward(x: tensor[1x3]) = (x + x * 0.5) + (x + x * 0.5) * -0.25
let x = [[1, 2, 3]]
let d2 = [[1, 1, 1]]
let d1 = d2 + d2 * -0.25
let d0 = d1 + d1 * 0.5
print d0
print (forward(x + [[0.01, 0, 0]]) - forward(x - [[0.01, 0, 0]])) / 0.02
""")
write("03_train_10_steps.mg", M.train_program(steps=10, checkpoints=[0, 1, 10]))
write("04_train_200_steps.mg", M.train_program())
write("errors/e1_head_output_of_the_wrong_width.mg", """# A head of width 4 produces a 6 x 4 result; its output matrix must be 4 x 8 to bring it back to the model width 8. A 2 x 8 matrix does not fit, and the compiler says so.
let o = [[1, 2, 3, 4], [1, 2, 3, 4], [1, 2, 3, 4], [1, 2, 3, 4], [1, 2, 3, 4], [1, 2, 3, 4]]
let wo = [[1, 0, 0, 0, 0, 0, 0, 0], [0, 1, 0, 0, 0, 0, 0, 0]]
print o @ wo
""")
write("errors/e2_missing_argument.mg", """# ln_back takes three arguments (the upstream gradient, the layer's input and the scale). Two is an arity error, reported before any code exists.
def ln_sigma(h: tensor[2x4]) = sqrt(row_mean((h - row_mean(h)) * (h - row_mean(h))) + 0.00001)
def ln_hat(h: tensor[2x4]) = (h - row_mean(h)) / ln_sigma(h)
def ln_back(d: tensor[2x4], h: tensor[2x4], g: tensor[1x4]) = ((d * g) - row_mean(d * g) - ln_hat(h) * row_mean((d * g) * ln_hat(h))) / ln_sigma(h)
print ln_back([[1, 2, 3, 4], [4, 3, 2, 1]], [[1, 2, 4, 8], [8, 4, 2, 1]])
""")
write("errors/e3_residual_of_the_wrong_width.mg", """# A residual connection adds a block's output to its input, so the widths must agree. If the head's output matrix is forgotten, the 6 x 4 head result cannot be added to the 6 x 8 input.
let x = [[1, 2, 3, 4, 5, 6, 7, 8], [1, 2, 3, 4, 5, 6, 7, 8], [1, 2, 3, 4, 5, 6, 7, 8], [1, 2, 3, 4, 5, 6, 7, 8], [1, 2, 3, 4, 5, 6, 7, 8], [1, 2, 3, 4, 5, 6, 7, 8]]
let o = [[1, 2, 3, 4], [1, 2, 3, 4], [1, 2, 3, 4], [1, 2, 3, 4], [1, 2, 3, 4], [1, 2, 3, 4]]
print x + o
""")
P = {k: M.name(k) for k in M.ORDER}
f, lg = M.forward_lines("", "x", P); b, G = M.backward_lines("", "x", "y", P)
write("../lm2.mg.defs", M.comments() + "# (This listing is one training step with every step's suffix removed: the parameters are named after their matrices, e.g. wq1_2 is block 2's query matrix for head 1.\n# In the training programs each step's lets carry a suffix such as _s7, and the parameters are numbered per step, e.g. wq1_2_v200.)\n\n" + M.defs() + "\n# ---- the forward pass, one let per step\n" + "\n".join(f) + "\n# ---- the loss, and the number of correct predictions\n# loss    = " + M.loss_expr(lg, "y") + "\n# correct = " + M.correct_expr(lg, "y") + "\n\n# ---- the backward pass, one let per step, working backwards from the loss\n" + "\n".join(b) + "\n\n# ---- the update, one per matrix (lr = " + str(M.LR) + ")\n" + "\n".join(f"let {M.name(k)}_new = {M.name(k)} - {G[k]} * {M.LR}" for k in M.ORDER) + "\n")
