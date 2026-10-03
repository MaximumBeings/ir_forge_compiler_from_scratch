#!/usr/bin/env python3
"""Writes the Chapter 35 example programs. The training programs are generated from lm_lib (so a page example cannot drift from the definitions)."""
import os
import lm_lib as M
here = os.path.join(os.path.dirname(os.path.abspath(__file__)), "examples")
def write(name, text): open(os.path.join(here, name), "w").write(text)

write("01_stacked_causal_mask.mg", """# Two sequences of three tokens are stacked into one 6-row matrix, so attention is computed over all 6 rows at once. The mask must let row r look at
# column c only if c is in the SAME sequence and c <= r. Entries that must not be seen get -1000000000, which softmax turns into exactly 0.
# (Rows 0-2 are sequence one, rows 3-5 sequence two.) The scores are made up: each is 1, so without the mask every row would be uniform.
def softmax_rows(m: tensor[6x6]) = exp(m - row_max(m)) / row_sum(exp(m - row_max(m)))
let mask = [[0, -1000000000, -1000000000, -1000000000, -1000000000, -1000000000], [0, 0, -1000000000, -1000000000, -1000000000, -1000000000], [0, 0, 0, -1000000000, -1000000000, -1000000000], [-1000000000, -1000000000, -1000000000, 0, -1000000000, -1000000000], [-1000000000, -1000000000, -1000000000, 0, 0, -1000000000], [-1000000000, -1000000000, -1000000000, 0, 0, 0]]
let scores = [[1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1]]
print softmax_rows(scores + mask)
# Each row sums to 1; row 0 is all on itself, row 2 is 1/3 each on rows 0-2, row 5 is 1/3 each on rows 3-5, and nothing leaks between the two sequences.
print row_sum(softmax_rows(scores + mask))
""")
write("02_masked_cross_entropy.mg", """# Only some rows of the stacked matrix are predictions. Here a 4-row logits matrix over 3 words, of which rows 1 and 3 are targets (mr is 1 on them, 0 elsewhere).
# y holds the correct next word one-hot on the target rows and zeros elsewhere. The loss averages over the 2 target rows (hence the 0.5), and the gradient with
# respect to the logits is (softmax(z) * mr - y) * 0.5: the rows that are not targets get exactly zero gradient.
def log_softmax(z: tensor[4x3]) = z - row_max(z) - log(row_sum(exp(z - row_max(z))))
let z = [[1, 2, 3], [0, 0, 0], [5, 1, 1], [1, 3, 2]]
let mr = [[0], [1], [0], [1]]
let y = [[0, 0, 0], [0, 1, 0], [0, 0, 0], [0, 0, 1]]
print col_sum(row_sum(y * log_softmax(z))) * -0.5
print (exp(log_softmax(z)) * mr - y) * 0.5
# Second row: three equal logits give each word 1/3; the correct word is the middle one, so that row's gradient is (1/3, 1/3 - 1, 1/3) / 2 = (0.1667, -0.3333, 0.1667).
""")
write("03_train_10_steps.mg", M.train_program(steps=10, checkpoints=[0, 1, 10]))
write("04_train_200_steps.mg", M.train_program())
write("errors/e1_mask_of_the_wrong_size.mg", """# The mask must be as large as the score matrix: 6 x 6 here. A 4 x 4 mask does not fit, and the compiler says so.
def softmax_rows(m: tensor[6x6]) = exp(m - row_max(m)) / row_sum(exp(m - row_max(m)))
let scores = [[1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1]]
let mask = [[0, -1000000000, -1000000000, -1000000000], [0, 0, -1000000000, -1000000000], [0, 0, 0, -1000000000], [0, 0, 0, 0]]
print softmax_rows(scores + mask)
""")
write("errors/e2_missing_argument.mg", """# ln_back takes three arguments (the upstream gradient, the layer's input and the scale). Two is an arity error, reported before any code exists.
def ln_sigma(h: tensor[2x4]) = sqrt(row_mean((h - row_mean(h)) * (h - row_mean(h))) + 0.00001)
def ln_hat(h: tensor[2x4]) = (h - row_mean(h)) / ln_sigma(h)
def ln_back(d: tensor[2x4], h: tensor[2x4], g: tensor[1x4]) = ((d * g) - row_mean(d * g) - ln_hat(h) * row_mean((d * g) * ln_hat(h))) / ln_sigma(h)
print ln_back([[1, 2, 3, 4], [4, 3, 2, 1]], [[1, 2, 4, 8], [8, 4, 2, 1]])
""")
write("errors/e3_stacked_rows_do_not_match.mg", """# The tokens matrix has one row per token of every stacked sequence (6 here); the mask-row vector must have the same 6 rows. A 4-row one cannot multiply it.
let logits = [[1, 2, 3], [1, 2, 3], [1, 2, 3], [1, 2, 3], [1, 2, 3], [1, 2, 3]]
let mr = [[0], [1], [0], [1]]
print logits * mr
""")
P = {k: M.NAMES[k] for k in M.ORDER}
f, lg = M.forward_lines("", "x", P); b, G = M.backward_lines("", "x", "y", P)
write("../lm.mg.defs", M.comments() + "# (This listing is one training step with every step's suffix removed: the parameters are named after their matrices, e.g. e is the embedding. In the training\n# programs each step's lets carry a suffix such as _s7, and the parameters are numbered per step, e0 .. e200.)\n\n" + M.defs() + "\n# ---- the forward pass, one let per step\n" + "\n".join(f) + "\n# ---- the loss, and the number of correct predictions\n# loss    = " + M.loss_expr(lg, "y") + "\n# correct = " + M.correct_expr(lg, "y") + "\n\n# ---- the backward pass, one let per step, working backwards from the loss\n" + "\n".join(b) + "\n\n# ---- the update, one per matrix (lr = 1.0)\n" + "\n".join(f"let {M.NAMES[k]}_new = {M.NAMES[k]} - {G[k]} * {M.LR}" for k in M.ORDER) + "\n")
