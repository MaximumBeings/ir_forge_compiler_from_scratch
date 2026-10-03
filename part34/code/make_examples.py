#!/usr/bin/env python3
"""Writes the Chapter 34 example programs. The training programs are generated from ffn_lib (so a page example cannot drift from the definitions)."""
import os
import ffn_lib as F
here = os.path.join(os.path.dirname(os.path.abspath(__file__)), "examples")
def write(name, text): open(os.path.join(here, name), "w").write(text)

write("01_layer_norm_backward.mg", """# Backward through layer normalisation. y = (h - mean(h)) / sigma with sigma = sqrt(variance(h) + 0.00001), for ONE row of four numbers h.
# If the loss is L = sum(d * y) for a fixed upstream gradient d, the derivative of L with respect to h is
#     (d - mean(d) - y * mean(d * y)) / sigma
# (three terms, because every h_i changes the mean, the spread and so every y_j). The first matrix is that formula; the next four are the same
# derivatives found by brute force: nudge one entry of h by 0.01 up and by 0.01 down and watch L change.
def ln_sigma(h: tensor[1x4]) = sqrt(row_mean((h - row_mean(h)) * (h - row_mean(h))) + 0.00001)
def ln_hat(h: tensor[1x4]) = (h - row_mean(h)) / ln_sigma(h)
def loss(h: tensor[1x4], d: tensor[1x4]) = row_sum(d * ln_hat(h))
def backward(h: tensor[1x4], d: tensor[1x4]) = (d - row_mean(d) - ln_hat(h) * row_mean(d * ln_hat(h))) / ln_sigma(h)
let h = [[1, 2, 4, 8]]
let d = [[1, -2, 3, 0.5]]
print backward(h, d)
print (loss(h + [[0.01, 0, 0, 0]], d) - loss(h - [[0.01, 0, 0, 0]], d)) / 0.02
print (loss(h + [[0, 0.01, 0, 0]], d) - loss(h - [[0, 0.01, 0, 0]], d)) / 0.02
print (loss(h + [[0, 0, 0.01, 0]], d) - loss(h - [[0, 0, 0.01, 0]], d)) / 0.02
print (loss(h + [[0, 0, 0, 0.01]], d) - loss(h - [[0, 0, 0, 0.01]], d)) / 0.02
# Two things to see: the formula's four numbers add up to (nearly) zero (adding the same amount to every h changes nothing, so the gradients must cancel),
# and the brute-force numbers agree with the formula to about four digits (the step 0.01 and the six printed digits limit the agreement).
print row_sum(backward(h, d))
""")
write("02_relu_backward.mg", """# Backward through relu. y = max(0, p). The derivative is 1 where p is positive and 0 where it is negative, so the gradient d passes through where
# p >= 0 and is cut where p < 0: dp = d * ge(p, 0). (ge is the comparison of Chapter 32; [[0]] is a 1x1 matrix, stretched across the row.)
# At p = 0 exactly the true derivative does not exist (a corner); this program, like most training code, passes the gradient there. The brute-force
# estimate at a corner is the average of the two sides, half of d. The second row shows it.
let p = [[-1.5, 0, 2, 3]]
let d = [[1, 2, 3, 4]]
print d * ge(p, [[0]])
print (row_sum(d * relu(p + [[0.01, 0, 0, 0]])) - row_sum(d * relu(p - [[0.01, 0, 0, 0]]))) / 0.02
print (row_sum(d * relu(p + [[0, 0.01, 0, 0]])) - row_sum(d * relu(p - [[0, 0.01, 0, 0]]))) / 0.02
print (row_sum(d * relu(p + [[0, 0, 0.01, 0]])) - row_sum(d * relu(p - [[0, 0, 0.01, 0]]))) / 0.02
print (row_sum(d * relu(p + [[0, 0, 0, 0.01]])) - row_sum(d * relu(p - [[0, 0, 0, 0.01]]))) / 0.02
""")
write("03_train_attention_only.mg", F.train_program("A"))
write("04_train_with_ffn.mg", F.train_program("B"))
LN1 = """def ln_sigma(h: tensor[1x4]) = sqrt(row_mean((h - row_mean(h)) * (h - row_mean(h))) + 0.00001)
def ln_hat(h: tensor[1x4]) = (h - row_mean(h)) / ln_sigma(h)
def ln_out(h: tensor[1x4], gm: tensor[1x4], bt: tensor[1x4]) = ln_hat(h) * gm + bt"""
write("errors/e1_scale_of_the_wrong_width.mg", f"""# layer norm's scale is one number per feature: 1 x 4 here. A 1 x 3 scale does not fit, and the compiler says so.
{LN1}
print ln_out([[1, 2, 3, 4]], [[1, 1, 1]], [[0, 0, 0, 0]])
""")
write("errors/e2_missing_argument.mg", f"""# ln_out takes three arguments (the row, the scale and the shift). Two is an arity error, reported before any code exists.
{LN1}
print ln_out([[1, 2, 3, 4]], [[1, 1, 1, 1]])
""")
write("errors/e3_residual_shapes_differ.mg", """# A residual connection adds a sublayer's output to its input, so the shapes must agree. A 54 x 8 hidden layer cannot be added to a 54 x 4 input.
let x = [[1, 2, 3, 4], [5, 6, 7, 8]]
let hidden = [[1, 2, 3, 4, 5, 6, 7, 8], [1, 2, 3, 4, 5, 6, 7, 8]]
print x + hidden
""")
write("../attention_ffn.mg.defs", F.comments("B") + "# (The same functions exist again with the suffix _27 for chunks of 27 sequences; only the sizes differ.)\n\n" + F.defs("B", len(F.TRAIN), "", grads=True))
