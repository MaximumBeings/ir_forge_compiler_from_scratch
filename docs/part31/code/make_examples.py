#!/usr/bin/env python3
"""Writes the Chapter 31 example programs. Short ones are assembled from lines of bigram.mg.defs where they use the same definitions."""
import os, re
import bigram_lib as B
here = os.path.join(os.path.dirname(os.path.abspath(__file__)), "examples")
defs = {m.group(1): l for l in B.DEFS.split("\n") for m in [re.match(r"def (\w+)\(", l)] if m}
def write(name, text): open(os.path.join(here, name), "w").write(text)

write("01_log.mg", """# log(x) is the natural logarithm: the power e must be raised to in order to get x. It undoes exp.
print log([[1, 2.718281828459045, 10], [0.5, 100, 0.001]])      # log(1) = 0, log(e) = 1, log(10) = 2.30259; numbers below 1 give negative logs
print exp(log([[1, 2, 10], [0.5, 100, 0.001]]))                  # exp undoes log (to the printed digits)
print log([[0]])                                                 # log of 0 is minus infinity: no power of e is 0
print log([[-1]])                                                # log of a negative number is not a number (nan)
# log turns products into sums: log(a*b) = log(a) + log(b). Both lines print the same two numbers.
print log([[6, 0.5]] * [[7, 8]])
print log([[6, 0.5]]) + log([[7, 8]])
""")
write("02_cross_entropy.mg", """# Cross-entropy: how surprised a model is by what really happened. For each case, y is a one-hot row marking the token that really came next and p is
# the model's probability row; y * log(p) keeps only the log-probability the model gave the right token, and minus its average is the loss.
# Four cases (rows) over three tokens: a model with no idea, a confident correct model, a confident WRONG model, and a coin-flip between two.
let p = [[0.3333333333333333, 0.3333333333333333, 0.3333333333333333], [0.98, 0.01, 0.01], [0.01, 0.98, 0.01], [0.5, 0.5, 0.0000001]]
let y = [[1, 0, 0], [1, 0, 0], [1, 0, 0], [1, 0, 0]]
print row_sum(y * log(p)) * -1                      # the surprise of each case: log(3) = 1.0986, 0.0202, 4.6052 (very wrong), 0.6931 (one bit)
print col_sum(row_sum(y * log(p))) * -0.25          # the loss: the average surprise, (1.0986 + 0.0202 + 4.6052 + 0.6931) / 4 = 1.6043
""")
write("03_one_gradient_step.mg", """# One step of gradient descent by hand. Two tokens (0 and 1) and four (current, next) pairs: 0 -> 1, 0 -> 1, 0 -> 0, 1 -> 0.
# w starts at zero, so every probability is 1/2. The gradient of the loss is  transpose(x) @ (softmax(x @ w) - y) / 4.
# Row 0 of w sees three pairs: two push toward token 1, one toward token 0, so the gradient is [0.5, -0.5] / 4 = [0.125, -0.125]. Row 1 sees one pair (1 -> 0): [-0.125, 0.125].
def log_softmax(s: tensor[4x2]) = s - row_max(s) - log(row_sum(exp(s - row_max(s))))
def loss(w: tensor[2x2], x: tensor[4x2], y: tensor[4x2]) = col_sum(row_sum(y * log_softmax(x @ w))) * -0.25
def gradient(w: tensor[2x2], x: tensor[4x2], y: tensor[4x2]) = transpose(x) @ (exp(log_softmax(x @ w)) - y) * 0.25
let x = [[1, 0], [1, 0], [1, 0], [0, 1]]
let y = [[0, 1], [0, 1], [1, 0], [1, 0]]
let w = [[0, 0], [0, 0]]
print loss(w, x, y)                      # log(2) = 0.693147: with no information every token is a coin flip
print gradient(w, x, y)                  # [[0.125, -0.125], [-0.125, 0.125]]
let w1 = w - gradient(w, x, y)           # one step with learning rate 1
print w1                                 # [[-0.125, 0.125], [0.125, -0.125]]: each row moves toward the token that followed it more often
print loss(w1, x, y)                     # smaller than before: the step helped
""")
write("04_training.mg", B.train_program())
write("errors/e1_wrong_number_of_pairs.mg", defs["loss"].replace("def loss", "def loss_unused", 1) and f"""# The data are 14 pairs. Thirteen rows do not fit the 14x5 parameters, and the compiler says so.
{defs['log_softmax']}
{defs['loss']}
let w = [[0, 0, 0, 0, 0], [0, 0, 0, 0, 0], [0, 0, 0, 0, 0], [0, 0, 0, 0, 0], [0, 0, 0, 0, 0]]
let x13 = {B.lit(B.X[:13])}
let y13 = {B.lit(B.Y[:13])}
print loss(w, x13, y13)
""")
write("errors/e2_log_of_a_scalar.mg", "# log is applied to a matrix. A bare number in the source is a compile-time scalar.\nprint log(2)\n")
write("errors/e3_weights_the_wrong_size.mg", f"""# The weights must be 5x5 (one row per token, one column per next token). A 4x5 matrix does not fit.
{defs['log_softmax']}
{defs['loss']}
{defs['gradient']}
{defs['step']}
let w = [[0, 0, 0, 0, 0], [0, 0, 0, 0, 0], [0, 0, 0, 0, 0], [0, 0, 0, 0, 0]]
let x = {B.lit(B.X)}
let y = {B.lit(B.Y)}
print step(w, x, y)
""")
