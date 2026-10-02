#!/usr/bin/env python3
"""READ THIS FIRST: this script writes WRONG versions of the trainer (bigram.mg.defs with one mistake each) and runs check_bigram.py on each. A "caught" line
(the checker reported FAIL, or the program did not even compile) is the EXPECTED, wanted result: it shows the checker can notice that mistake. "NOT CAUGHT"
means the checker cannot tell the wrong trainer from the right one (reported honestly). Output: model_mutation_out.txt"""
import os, subprocess, sys
here = os.path.dirname(os.path.abspath(__file__)); work = os.path.join(here, "work", "model_mut"); os.makedirs(work, exist_ok=True)
good = open(os.path.join(here, "bigram.mg.defs")).read()
print("NOTE: this script deliberately runs wrong trainers. 'caught' lines are EXPECTED: they show the checker can detect the mistake.")
def check(defs_text, label):
    path = os.path.join(work, "mutant.defs"); open(path, "w").write(defs_text)
    r = subprocess.run([sys.executable, os.path.join(here, "check_bigram.py")], capture_output=True, text=True, env=dict(os.environ, MG_DEFS_FILE=path), timeout=900)
    fails = [l.strip()[5:].strip() for l in r.stdout.split("\n") if l.strip().startswith("FAIL")]
    if r.returncode != 0 and not fails: print(f"{label}: caught (the program did not even run: {(r.stderr or r.stdout).strip().splitlines()[-1][:110]})"); return
    if fails:
        kinds = []
        for f in fails:
            k = ("the reference" if ("reference" in f or "equal" in f) else "the loss" if ("loss" in f or "entropy" in f) else "what it learned" if "token" in f and "probabilities" in f else "finite differences" if "finite" in f else "unseen row" if "token 4" in f or "gradient is exactly" in f or "uniform" in f else "other")
            if k not in kinds: kinds.append(k)
        print(f"{label}: caught by {len(fails)} failing checks ({', '.join(kinds)})")
    else: print(f"{label}: NOT CAUGHT")
out = subprocess.run([sys.executable, os.path.join(here, "check_bigram.py")], capture_output=True, text=True).stdout
print("baseline (nothing broken):", "checker passes (expected)" if "all checks pass" in out else "UNEXPECTED FAILURE")
def mut(label, old, new):
    if old not in good: print(f"{label}: MUTATION DID NOT APPLY"); return
    check(good.replace(old, new, 1), label)
mut("the gradient has the wrong sign (y minus p instead of p minus y)", "(exp(log_softmax(x @ w)) - y) * 0.07142857142857142", "(y - exp(log_softmax(x @ w))) * 0.07142857142857142")
mut("the gradient is not averaged over the 14 pairs", "- y) * 0.07142857142857142", "- y)")
mut("the gradient forgets to subtract the targets y", "(exp(log_softmax(x @ w)) - y) * 0.07142857142857142", "(exp(log_softmax(x @ w))) * 0.07142857142857142")
mut("the gradient uses x instead of its transpose", "transpose(x) @ (exp", "x @ (exp")
mut("the loss has the wrong sign", "* -0.07142857142857142", "* 0.07142857142857142")
mut("the loss is averaged over 5, not 14", "* -0.07142857142857142", "* -0.2")
mut("the loss does not use the targets (it sums every token's log-probability)", "row_sum(y * log_softmax(x @ w))", "row_sum(log_softmax(x @ w))")
mut("log_softmax forgets the log of the sum (it only subtracts the maximum)", "s - row_max(s) - log(row_sum(exp(s - row_max(s))))", "s - row_max(s)")
mut("log_softmax does not subtract the row maximum (the naive log-sum-exp)", "s - row_max(s) - log(row_sum(exp(s - row_max(s))))", "s - log(row_sum(exp(s)))")
mut("the step moves uphill (adds the gradient)", "w - gradient(w, x, y) * 8", "w + gradient(w, x, y) * 8")
mut("the learning rate is 4, not 8", "gradient(w, x, y) * 8", "gradient(w, x, y) * 4")
mut("the probabilities do not subtract the row maximum (naive softmax)", "def probabilities(w: tensor[5x5]) = exp(w - row_max(w)) / row_sum(exp(w - row_max(w)))", "def probabilities(w: tensor[5x5]) = exp(w) / row_sum(exp(w))")
