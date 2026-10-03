#!/usr/bin/env python3
"""Builds the three ground-truth programs of this chapter from the programs of Chapters 33, 34 and 35 (so the hand-derived gradients are those chapters' own code, copied, not re-typed):
each program computes a loss at the chapters' initial weights, then prints the HAND-DERIVED gradients. autograd.py differentiates the first print; check_autograd.py compares.
Writes examples/h33_attention.mg, examples/h34_layer_norm.mg, examples/h35_transformer_step1.mg."""
import os
here = os.path.dirname(os.path.abspath(__file__)); root = os.path.join(here, "..", "..")
def lines(part, name, a, b): return open(os.path.join(root, part, "code", "examples", name)).read().split("\n")[a - 1:b]
def write(name, header, body, prints):
    open(os.path.join(here, "examples", name), "w").write("# " + header + "\n" + "\n".join(body) + "\n" + "\n".join(prints) + "\n")
# Chapter 33: attention classifier, 24 sequences; the definitions (lines 5-19), the training set (37-39) and the initial weights (95-98) of 03_train.mg
write("h33_attention.mg", "Chapter 33's attention classifier at its initial weights. The first print is the LOSS; the next four are Chapter 33's HAND-DERIVED gradients for q0, wk0, wv0 and wo0.",
      lines("part33", "03_train.mg", 5, 19) + lines("part33", "03_train.mg", 37, 39) + lines("part33", "03_train.mg", 95, 98),
      ["print loss(x, g, q0, wk0, wv0, wo0, y)"] + [f"print grad_{n}(x, g, q0, wk0, wv0, wo0, y)" for n in ("q", "wk", "wv", "wo")])
# Chapter 34: layer normalisation backward for one row of four numbers (the definitions and data of 01_layer_norm_backward.mg, without its prints)
write("h34_layer_norm.mg", "Chapter 34's layer normalisation. The first print is the loss sum(d * ln_hat(h)); the second is Chapter 34's HAND-DERIVED gradient with respect to h.",
      lines("part34", "01_layer_norm_backward.mg", 5, 11), ["print loss(h, d)", "print backward(h, d)"])
# Chapter 35: one transformer block (layer norms, causal attention, residuals, feed-forward, output layer), 16 sequences of 7 tokens: its definitions and data (1-48) and the whole of its
# step-1 forward and hand-derived backward pass (50-93). The 16 parameters and the names of their hand-derived gradients:
P = [("e0", "Ge"), ("g10", "Gg1"), ("n10", "Gn1"), ("wq0", "Gwq"), ("wk0", "Gwk"), ("wv0", "Gwv"), ("wo0", "Gwo"), ("g20", "Gg2"), ("n20", "Gn2"), ("w10", "Gw1"), ("c10", "Gc1"), ("w20", "Gw2"), ("c20", "Gc2"), ("gf0", "Ggf"), ("nf0", "Gnf"), ("wu0", "Gwu")]
write("h35_transformer_step1.mg", "Chapter 35's transformer block at its initial weights (step 1). The first print is the LOSS (Chapter 35's own expression); the next 16 are Chapter 35's HAND-DERIVED gradients, in the order e0 g10 n10 wq0 wk0 wv0 wo0 g20 n20 w10 c10 w20 c20 gf0 nf0 wu0.",
      lines("part35", "03_train_10_steps.mg", 1, 48) + lines("part35", "03_train_10_steps.mg", 50, 93),
      ["print col_sum(row_sum(y * log_softmax(lg_s1))) * -0.015625"] + [f"print {g}_s1" for _, g in P])
print("wrote 3 programs")
