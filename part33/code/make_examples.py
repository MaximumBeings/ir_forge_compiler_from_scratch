#!/usr/bin/env python3
"""Writes the Chapter 33 example programs. The training program is generated from attn_lib (so a page example cannot drift from the definitions)."""
import os
import attn_lib as A
here = os.path.join(os.path.dirname(os.path.abspath(__file__)), "examples")
def write(name, text): open(os.path.join(here, name), "w").write(text)

# 01: attention for ONE sequence, by hand. Tokens 1, 3, 2, 0; keys have a single non-zero number each, so the scores can be read off.
write("01_attention_by_hand.mg", """# Attention for one sequence of four tokens (1, 3, 2, 0), small enough to follow by hand. Each token has a 2-number key and a 2-number value.
# The query is (1, 0), so a token's score is just the first number of its key (times 1/sqrt(2) = 0.7071), and the second number of a value is 0 for tokens 1 and 3.
let x  = [[0, 1, 0, 0, 0], [0, 0, 0, 1, 0], [0, 0, 1, 0, 0], [1, 0, 0, 0, 0]]         # the four tokens, one-hot
let wk = [[0, 0], [2, 0], [1, 0], [1.5, 0], [0, 0]]                                      # key of each of the five tokens
let wv = [[1, 1], [10, 0], [0, 10], [5, 0], [0, 0]]                                      # value of each of the five tokens
let q  = [[1, 0]]
let scores = (x @ wk) @ transpose(q) * 0.7071067811865476        # 4x1: token 1 scores 2, token 3 scores 1.5, token 2 scores 1, token 0 scores 0 (all times 0.7071)
print scores
let a = exp(transpose(scores) - row_max(transpose(scores))) / row_sum(exp(transpose(scores) - row_max(transpose(scores))))      # softmax over the four scores: 1x4 attention weights
print a
print a @ (x @ wv)                                                # the attended value: the average of the four values, weighted by attention
""")
write("02_softmax_backward.mg", """# The one new piece of calculus in this chapter: how the loss changes when the scores of a softmax change.
# If L = (d . softmax(s)) for a fixed vector d, the derivative with respect to s_i is  a_i * (d_i - sum_j a_j d_j)  where a = softmax(s).
# The first line prints that formula; the second computes the same derivatives by brute force (nudge each score by 0.01 up and down and watch L change).
def softmax(s: tensor[1x3]) = exp(s - row_max(s)) / row_sum(exp(s - row_max(s)))
def loss(s: tensor[1x3], d: tensor[1x3]) = row_sum(d * softmax(s))
def backward(s: tensor[1x3], d: tensor[1x3]) = softmax(s) * (d - row_sum(softmax(s) * d))
let s = [[0.5, -1, 2]]
let d = [[3, -2, 1]]
print backward(s, d)
print (loss(s + [[0.01, 0, 0]], d) - loss(s - [[0.01, 0, 0]], d)) / 0.02       # nudge s_0
print (loss(s + [[0, 0.01, 0]], d) - loss(s - [[0, 0.01, 0]], d)) / 0.02       # nudge s_1
print (loss(s + [[0, 0, 0.01]], d) - loss(s - [[0, 0, 0.01]], d)) / 0.02       # nudge s_2
""")
write("03_train.mg", A.train_program())
D = A.defs(len(A.TRAIN), "")
lines = {l.split("(")[0][4:]: l for l in D.split("\n") if l.startswith("def ")}
write("errors/e1_one_sequence_short.mg", f"""# The defs were written for 24 sequences (96 token rows). A batch of 23 sequences (92 rows) does not fit, and the compiler says so.
{lines['softmax_rows']}
{lines['attn_matrix']}
let x = {A.lit(A.onehot_rows(A.TRAIN[:23]))}
print attn_matrix(x, [[0.1, 0.2, 0.3]], [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]])
""")
write("errors/e2_group_matrix_transposed.mg", f"""# The group matrix is 24 x 96 (one row per sequence). Passing its transpose, 96 x 24, is a shape error caught when compiling.
{lines['softmax_rows']}
{lines['attn_matrix']}
{lines['context']}
let x = {A.lit(A.onehot_rows(A.TRAIN))}
let g_wrong = {A.lit([list(r) for r in zip(*A.group_matrix(len(A.TRAIN)))])}
let w = [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]]
print context(x, g_wrong, [[0, 0, 0]], w, w)
""")
write("errors/e3_reshape_element_count.mg", """# reshape keeps the numbers, so the counts must match: 8 numbers cannot fill a 4 x 3 shape (12 numbers). (The chapter reshapes 96 x 1 to 24 x 4: the same 96 numbers.)
let a = [[1], [2], [3], [4], [5], [6], [7], [8]]
print reshape(a, 4, 3)
""")
# the definitions as shown on the page: the training size (24 sequences) with the backward pass; the held-out (40) and exhaustive (25) copies differ only in the numbers
write("../attention.mg.defs", A.COMMENTS + "# (The same functions exist again with the suffix _te for the 40 held-out sequences and _ex for chunks of 25 sequences; only the sizes differ.)\n\n" + A.defs(len(A.TRAIN), "", gradients=True))
