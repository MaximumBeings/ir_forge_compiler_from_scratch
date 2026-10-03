#!/usr/bin/env python3
"""READ THIS FIRST: this script writes WRONG versions of the model's definitions (one mistake each, mostly in the hand-derived backward pass through the heads, the blocks, the
layer normalisations and the residual connections; several touch only ONE head or ONE block) and runs check_lm2.py (the lean mode: seed 1, finite differences for six weights,
then 10 training steps against the reference) on each. A "caught" line (the checker reported FAIL, or the program did not compile) is the EXPECTED, wanted result: it shows the
checker can notice that mistake. "NOT CAUGHT" would be a gap, and is reported as such. Each run takes about a minute and a half. Output: model_mutation_out.txt"""
import os, subprocess, sys
here = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, here)
import lm2_lib as M, lm2_ref as R
print("NOTE: this script deliberately runs wrong programs. 'caught' lines are EXPECTED: they show the checker can detect the mistake.")
good = M.gradient_program(R.init_params(1), []) + M.train_program(steps=1, checkpoints=[0])
def check(old, new, label):
    r = subprocess.run([sys.executable, os.path.join(here, "check_lm2.py"), "--lean"], capture_output=True, text=True, env=dict(os.environ, MG_MUTANT_OLD=old, MG_MUTANT_NEW=new), timeout=3600)
    fails = [l.strip()[5:].strip() for l in r.stdout.split("\n") if l.strip().startswith("FAIL")]
    if r.returncode != 0 and not fails: print(f"{label}: caught (the program did not even run: {(r.stderr or r.stdout).strip().splitlines()[-1][:110]})"); return
    if fails:
        kinds = []
        for f in fails:
            k = "finite differences" if "finite" in f else "the reference gradient" if "gradient" in f else "the reference training run" if ("step" in f or "held-out" in f or "chunks" in f or "attention patterns of" in f) else "the mask check" if "mask" in f else "other"
            if k not in kinds: kinds.append(k)
        print(f"{label}: caught by {len(fails)} failing checks ({', '.join(kinds)})")
    else: print(f"{label}: NOT CAUGHT")
out = subprocess.run([sys.executable, os.path.join(here, "check_lm2.py"), "--lean"], capture_output=True, text=True).stdout
print("baseline (nothing broken):", "checker passes (expected)" if "all checks pass" in out else "UNEXPECTED FAILURE")
def mut(label, old, new):
    if good.count(old) < 1: print(f"{label}: MUTATION DID NOT APPLY"); return
    check(old, new, label)
mut("layer-norm backward misses the mean-subtraction term (everywhere)", "((d * g) - row_mean(d * g) - ln_hat(h)", "((d * g) - ln_hat(h)")
mut("layer-norm backward misses the projection term (everywhere)", " - ln_hat(h) * row_mean((d * g) * ln_hat(h))", "")
mut("layer-norm backward forgets to divide by sigma (everywhere)", "row_mean((d * g) * ln_hat(h))) / ln_sigma(h)", "row_mean((d * g) * ln_hat(h)))")
mut("softmax backward misses the row-sum correction in head 2 of block 2 ONLY", " - row_sum(a2_b2_g * da2_b2_g))", ")")
mut("the 1/sqrt(4) score scale is missing from dq in head 1 of block 1 ONLY", f"ds1_b1_g @ k1_b1_g * {M.SC}", "ds1_b1_g @ k1_b1_g")
mut("dk forgets to transpose ds in head 2 of block 1 ONLY", "transpose(ds2_b1_g) @ q2_b1_g", "ds2_b1_g @ q2_b1_g")
mut("the gradient of the cross-entropy is not masked to the scored rows", " * mr - y)", " - y)")
mut("the loss's 1/64 is 1/32 in the backward pass only", f"- y) * {1 / M.NT!r}", f"- y) * {2 / M.NT!r}")
mut("the relu mask is omitted in block 1 ONLY", " * ge(pre_b1_g, [[0]])", "")
mut("the relu mask is the wrong way round in block 2 ONLY", "ge(pre_b2_g, [[0]])", "ge([[0]], pre_b2_g)")
mut("the residual path is dropped from block 2's dx1 ONLY", "let dx1_b2_g = dX2_g + ln_back", "let dx1_b2_g = ln_back")
mut("the residual path is dropped between the blocks (block 1's input gradient)", "let dX0_g = dx1_b1_g + ln_back", "let dX0_g = ln_back")
mut("the value path of head 2 is dropped from du1 in block 2 ONLY", " + dv2_b2_g @ transpose(wv2_2_v0)", "")
mut("head 2's whole contribution is dropped from du1 in block 1 ONLY", " + dq2_b1_g @ transpose(wq2_1_v0) + dk2_b1_g @ transpose(wk2_1_v0) + dv2_b1_g @ transpose(wv2_1_v0)", "")
mut("head 2's gradient into its output matrix uses head 1's matrix (same shape) in block 1 ONLY", "do2_b1_g = dx1_b1_g @ transpose(wo2_1_v0)", "do2_b1_g = dx1_b1_g @ transpose(wo1_1_v0)")
mut("block 2's feed-forward backward uses block 1's w2 (same shape)", "(dX2_g @ transpose(w2_2_v0))", "(dX2_g @ transpose(w2_1_v0))")
mut("the forward pass lets every position see ALL 112 rows (no mask; the backward pass is unchanged)", " * " + M.SC + " + mk)", " * " + M.SC + ")")
mut("the position encodings are left out of the forward pass", " + ps\n", "\n")
mut("the layer-norm epsilon is 0.1 in the forward AND backward pass (consistent with itself, not with the reference)", "+ 1e-05)", "+ 0.1)")
mut("naive softmax (no row-max subtraction); algebraically identical, and the masked entries are exp(-1e9) = 0", "exp(m - row_max(m)) / row_sum(exp(m - row_max(m)))", "exp(m) / row_sum(exp(m))")
mut("the embedding's first update uses the wrong step size (0.25 instead of 0.5)", "e_v0 - Ge_s1 * 0.5", "e_v0 - Ge_s1 * 0.25")
