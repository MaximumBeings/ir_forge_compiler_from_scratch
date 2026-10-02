#!/usr/bin/env python3
"""READ THIS FIRST: this script writes WRONG versions of the transformer (transformer.mg.defs with one mistake each) and runs check_transformer.py on
each. A "caught" line (the checker reported FAIL) is the EXPECTED, wanted result: it shows the checker can notice that mistake. "NOT CAUGHT" means the
checker cannot tell the wrong model from the right one for these weights and tokens (reported honestly, with the reason where one is known).
Output: model_mutation_out.txt"""
import os, re, subprocess, sys
here = os.path.dirname(os.path.abspath(__file__)); work = os.path.join(here, "work", "model_mut"); os.makedirs(work, exist_ok=True)
good = open(os.path.join(here, "transformer.mg.defs")).read()
print("NOTE: this script deliberately runs wrong models. 'caught' lines are EXPECTED: they show the checker can detect the mistake.")
def check(defs_text, label):
    path = os.path.join(work, "mutant.defs"); open(path, "w").write(defs_text)
    r = subprocess.run([sys.executable, os.path.join(here, "check_transformer.py")], capture_output=True, text=True, env=dict(os.environ, MG_DEFS_FILE=path), timeout=900)
    fails = [l.strip()[5:].strip() for l in r.stdout.split("\n") if l.strip().startswith("FAIL")]
    if r.returncode != 0 and not fails: print(f"{label}: caught (the program did not even run: {(r.stderr or r.stdout).strip().splitlines()[-1][:110]})"); return
    if fails:
        kinds = []
        for f in fails:
            k = ("the reference" if "reference" in f else "causality" if ("rows 0" in f or "changing token" in f) else "permutation" if "order" in f or "positions" in f else "layer norm" if "random 4x4" in f else "probabilities" if "sum" in f else "other")
            if k not in kinds: kinds.append(k)
        print(f"{label}: caught by {len(fails)} failing checks ({', '.join(kinds)})")
    else: print(f"{label}: NOT CAUGHT")
out = subprocess.run([sys.executable, os.path.join(here, "check_transformer.py")], capture_output=True, text=True).stdout
print("baseline (nothing broken):", "checker passes (expected)" if "all checks pass" in out else "UNEXPECTED FAILURE")
def mut(label, old, new, count=1):
    if old not in good: print(f"{label}: MUTATION DID NOT APPLY"); return
    check(good.replace(old, new, count), label)
mut("the causal mask is not added to the attention scores", "* 0.7071067811865476 + mask)", "* 0.7071067811865476)")
mut("the 1/sqrt(d) scale is missing", "* 0.7071067811865476 + mask", " + mask")
mut("the layer-norm epsilon is 0.1 instead of 0.00001", "+ 0.00001)", "+ 0.1)")
mut("layer norm forgets its scale and shift", " * g + b\n", "\n")
mut("layer norm divides by the variance, not its square root", "/ sqrt(row_mean((x - row_mean(x)) * (x - row_mean(x))) + 0.00001)", "/ (row_mean((x - row_mean(x)) * (x - row_mean(x))) + 0.00001)")
mut("layer norm does not subtract the mean from the numerator", "def layer_norm(x: tensor[4x4], g: tensor[1x4], b: tensor[1x4]) = (x - row_mean(x)) /", "def layer_norm(x: tensor[4x4], g: tensor[1x4], b: tensor[1x4]) = x /")
mut("the attention sublayer has no residual connection", "= x + attention(layer_norm(x, g, bt)", "= attention(layer_norm(x, g, bt)")
mut("the feed-forward sublayer has no residual connection", "= x + ffn(layer_norm(x, g, bt)", "= ffn(layer_norm(x, g, bt)")
mut("the feed-forward network has no relu", "relu(x @ w1 + b1)", "(x @ w1 + b1)")
mut("a head's values come from the keys (wk instead of wv)", "@ (x @ wv)", "@ (x @ wk)")
mut("the two heads use the same output matrix (wo1 twice)", "head(x, wq2, wk2, wv2, mask) @ wo2", "head(x, wq2, wk2, wv2, mask) @ wo1")
mut("the keys are replaced by the queries (the scores are q times q-transposed)", "transpose(x @ wk)", "transpose(x @ wq)")
mut("the feed-forward bias b1 is added after the relu", "relu(x @ w1 + b1) @ w2 + b2", "relu(x @ w1) @ w2 + b1 @ w2 + b2")
mut("the attention softmax is the naive one (no row-maximum subtraction)", "def softmax(s: tensor[4x4]) = exp(s - row_max(s)) / row_sum(exp(s - row_max(s)))", "def softmax(s: tensor[4x4]) = exp(s) / row_sum(exp(s))")
mut("the vocabulary softmax is the naive one (no row-maximum subtraction)", "def softmax_vocab(s: tensor[4x5]) = exp(s - row_max(s)) / row_sum(exp(s - row_max(s)))", "def softmax_vocab(s: tensor[4x5]) = exp(s) / row_sum(exp(s))")
