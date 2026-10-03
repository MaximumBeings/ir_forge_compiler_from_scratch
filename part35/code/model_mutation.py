#!/usr/bin/env python3
"""READ THIS FIRST: this script writes WRONG versions of the language model's definitions (one mistake each, mostly in the hand-derived backward pass through
softmax attention, the layer normalisations, the relu and the residual connections) and runs check_lm.py (the quick mode: gradients against the reference and
against finite differences, then 10 training steps against the reference) on each. A "caught" line (the checker reported FAIL, or the program did not compile) is
the EXPECTED, wanted result: it shows the checker can notice that mistake. "NOT CAUGHT" would be a gap, and is reported as such. Each run takes about half a minute.
Output: model_mutation_out.txt"""
import os, subprocess, sys
here = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, here)
import lm_lib as M, lm_ref as R
print("NOTE: this script deliberately runs wrong backward passes. 'caught' lines are EXPECTED: they show the checker can detect the mistake.")
good = M.gradient_program(R.init_params(1), []) + M.train_program(steps=1, checkpoints=[0])
def check(old, new, label):
    r = subprocess.run([sys.executable, os.path.join(here, "check_lm.py")], capture_output=True, text=True, env=dict(os.environ, MG_MUTANT_OLD=old, MG_MUTANT_NEW=new), timeout=3600)
    fails = [l.strip()[5:].strip() for l in r.stdout.split("\n") if l.strip().startswith("FAIL")]
    if r.returncode != 0 and not fails: print(f"{label}: caught (the program did not even run: {(r.stderr or r.stdout).strip().splitlines()[-1][:110]})"); return
    if fails:
        kinds = []
        for f in fails:
            k = "finite differences" if "finite" in f else "the reference gradient" if "gradient" in f else "the reference training run" if ("step" in f or "held-out" in f or "chunks" in f) else "the mask check" if "mask" in f else "other"
            if k not in kinds: kinds.append(k)
        print(f"{label}: caught by {len(fails)} failing checks ({', '.join(kinds)})")
    else: print(f"{label}: NOT CAUGHT")
out = subprocess.run([sys.executable, os.path.join(here, "check_lm.py")], capture_output=True, text=True).stdout
print("baseline (nothing broken):", "checker passes (expected)" if "all checks pass" in out else "UNEXPECTED FAILURE")
def mut(label, old, new):
    if good.count(old) < 1: print(f"{label}: MUTATION DID NOT APPLY"); return
    check(old, new, label)
mut("layer-norm backward misses the mean-subtraction term", "((d * g) - row_mean(d * g) - ln_hat(h)", "((d * g) - ln_hat(h)")
mut("layer-norm backward misses the projection term", " - ln_hat(h) * row_mean((d * g) * ln_hat(h))", "")
mut("layer-norm backward forgets to divide by sigma", "row_mean((d * g) * ln_hat(h))) / ln_sigma(h)", "row_mean((d * g) * ln_hat(h)))")
mut("softmax backward misses the row-sum correction (ds = a * da)", " - row_sum(a_g * da_g))", ")")
mut("the 1/sqrt(8) score scale is missing from dq", f"ds_g @ k_g * {M.SC}", "ds_g @ k_g")
mut("dk forgets to transpose ds", "transpose(ds_g) @ q_g", "ds_g @ q_g")
mut("the gradient of the cross-entropy is not masked to the target rows", " * mr - y)", " - y)")
mut("the loss's 1/64 is 1/32 in the backward pass only", f"- y) * {1 / M.NT!r}", f"- y) * {2 / M.NT!r}")
mut("the relu mask is omitted (the gradient passes everywhere)", " * ge(pre_g, [[0]])", "")
mut("the relu mask is the wrong way round", "ge(pre_g, [[0]])", "ge([[0]], pre_g)")
mut("the residual path is dropped from dx1", "dx1_g = dx2_g + ln_back", "dx1_g = ln_back")
mut("the residual path is dropped from dx0 (the embedding gradient)", "dx0_g = dx1_g + ln_back", "dx0_g = ln_back")
mut("the value path is dropped from du1 (attention's three inputs become two)", " + dv_g @ transpose(wv0)", "")
mut("the forward pass lets every position see ALL 112 rows (no mask; the backward pass is unchanged)", " * " + M.SC + " + mk)", " * " + M.SC + ")")
mut("the position encodings are left out of the forward pass only", "@ e0 + ps", "@ e0")
mut("the layer-norm epsilon is 0.1 in the forward AND backward pass (consistent with itself, not with the reference)", "+ 1e-05)", "+ 0.1)")
mut("naive softmax (no row-max subtraction); algebraically identical, and the masked entries are exp(-1e9) = 0", "exp(m - row_max(m)) / row_sum(exp(m - row_max(m)))", "exp(m) / row_sum(exp(m))")
mut("the training step has the wrong learning rate (0.5 instead of 1.0)", " * 1.0\n", " * 0.5\n")
