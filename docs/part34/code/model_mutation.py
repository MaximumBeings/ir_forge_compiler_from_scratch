#!/usr/bin/env python3
"""READ THIS FIRST: this script writes WRONG versions of model B's definitions (one mistake each, mostly in the hand-derived backward pass through the layer
normalization, the relu and the residual connection) and runs check_ffn.py on each. A "caught" line (the checker reported FAIL, or the program did not
compile) is the EXPECTED, wanted result: it shows the checker can notice that mistake. "NOT CAUGHT" would be a gap. Each run takes about three minutes.
Output: model_mutation_out.txt"""
import os, subprocess, sys
here = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, here)
import ffn_lib as F
print("NOTE: this script deliberately runs wrong backward passes. 'caught' lines are EXPECTED: they show the checker can detect the mistake.")
CALL = "x, g, q, wk, wv, gm, bt, w1, b1, w2, b2, wo, y"; POOL = "pooled(x, g, q, wk, wv)"
good = F.defs("B", 54, "", grads=True) + F.defs("B", 27, "_27")
def check(old, new, label):
    r = subprocess.run([sys.executable, os.path.join(here, "check_ffn.py")], capture_output=True, text=True, env=dict(os.environ, MG_MUTANT_OLD=old, MG_MUTANT_NEW=new), timeout=3600)
    fails = [l.strip()[5:].strip() for l in r.stdout.split("\n") if l.strip().startswith("FAIL")]
    if r.returncode != 0 and not fails: print(f"{label}: caught (the program did not even run: {(r.stderr or r.stdout).strip().splitlines()[-1][:110]})"); return
    if fails:
        kinds = []
        for f in fails:
            k = ("finite differences" if "finite" in f else "the reference" if ("reference" in f or "equal" in f) else "the experiment" if ("model A" in f or "model B" in f or "0 0 0 0" in f) else "other")
            if k not in kinds: kinds.append(k)
        print(f"{label}: caught by {len(fails)} failing checks ({', '.join(kinds)})")
    else: print(f"{label}: NOT CAUGHT")
out = subprocess.run([sys.executable, os.path.join(here, "check_ffn.py")], capture_output=True, text=True).stdout
print("baseline (nothing broken):", "checker passes (expected)" if "all checks pass" in out else "UNEXPECTED FAILURE")
def mut(label, old, new):
    if good.count(old) < 1: print(f"{label}: MUTATION DID NOT APPLY"); return
    check(old, new, label)
mut("layer-norm backward misses the mean-subtraction term", f"d_hat({CALL}) - row_mean(d_hat({CALL})) - ln_hat(", f"d_hat({CALL}) - ln_hat(")
mut("layer-norm backward misses the projection term (the y * mean(d * y) part)", f" - ln_hat({POOL}) * row_mean(d_hat({CALL}) * ln_hat({POOL}))", "")
mut("layer-norm backward forgets to divide by sigma", f") / ln_sigma({POOL})\n", ")\n")
mut("the residual path is dropped from the gradient (d_h = the layer-norm path only)", f"= d_z({CALL}) + (d_hat", "= (d_hat")
mut("the relu mask is omitted (the gradient passes everywhere)", f" * ge(hidden_pre({POOL}, gm, bt, w1, b1), [[0]])", "")
mut("the relu mask is the wrong way round (passes where the input is NEGATIVE)", f"ge(hidden_pre({POOL}, gm, bt, w1, b1), [[0]])", f"ge([[0]], hidden_pre({POOL}, gm, bt, w1, b1))")
mut("grad_gm forgets to multiply by the normalised input", f"col_sum(d_u({CALL}) * ln_hat({POOL}))", f"col_sum(d_u({CALL}))")
mut("grad_w1 uses the un-normalised input instead of the layer-norm output", f"transpose(ln_out({POOL}, gm, bt)) @ d_pre", f"transpose({POOL}) @ d_pre")
mut("the layer-norm epsilon is 0.1 in the forward AND backward pass (consistent with itself, not with the reference)", "+ 1e-05)", "+ 0.1)")
mut("the forward pass drops the residual connection (the backward pass still has it)", f"= {POOL} + (relu(", "= (relu(")
