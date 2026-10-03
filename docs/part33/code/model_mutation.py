#!/usr/bin/env python3
"""READ THIS FIRST: this script writes WRONG versions of the attention classifier's definitions (one mistake each, mostly in the hand-derived backward pass)
and runs check_attention_training.py on each. A "caught" line (the checker reported FAIL, or the program did not compile) is the EXPECTED, wanted result: it
shows the checker can notice that mistake. "NOT CAUGHT" means the checker cannot tell the wrong version from the right one (reported honestly, with the
reason where one is known). Output: model_mutation_out.txt"""
import os, subprocess, sys
here = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, here)
import attn_lib as A
good = A.defs(24, "", gradients=True) + A.defs(40, "_te") + A.defs(25, "_ex")
print("NOTE: this script deliberately runs wrong backward passes. 'caught' lines are EXPECTED: they show the checker can detect the mistake.")
def check(old, new, label):
    r = subprocess.run([sys.executable, os.path.join(here, "check_attention_training.py")], capture_output=True, text=True, env=dict(os.environ, MG_MUTANT_OLD=old, MG_MUTANT_NEW=new), timeout=1800)
    fails = [l.strip()[5:].strip() for l in r.stdout.split("\n") if l.strip().startswith("FAIL")]
    if r.returncode != 0 and not fails: print(f"{label}: caught (the program did not even run: {(r.stderr or r.stdout).strip().splitlines()[-1][:110]})"); return
    if fails:
        kinds = []
        for f in fails:
            k = ("finite differences" if "finite" in f else "the reference" if ("reference" in f or "equal" in f) else "learning" if ("loss" in f or "classified" in f or "falls" in f) else "every sequence" if ("625" in f or "4 4 4 4" in f) else "attention scores" if "score" in f or "priority" in f else "other")
            if k not in kinds: kinds.append(k)
        print(f"{label}: caught by {len(fails)} failing checks ({', '.join(kinds)})")
    else: print(f"{label}: NOT CAUGHT")
out = subprocess.run([sys.executable, os.path.join(here, "check_attention_training.py")], capture_output=True, text=True).stdout
print("baseline (nothing broken):", "checker passes (expected)" if "all checks pass" in out else "UNEXPECTED FAILURE")
def mut(label, old, new):
    if good.count(old) < 1: print(f"{label}: MUTATION DID NOT APPLY"); return
    check(old, new, label)
sc = repr(A.SCALE)
mut("the softmax backward forgets its second term (treats the softmax as elementwise)", "d_attn_matrix(x, g, q, wk, wv, wo, y) - row_sum(attn_matrix(x, q, wk) * d_attn_matrix(x, g, q, wk, wv, wo, y))", "d_attn_matrix(x, g, q, wk, wv, wo, y)")
mut("grad_q forgets the 1/sqrt(d) scale", f"transpose(d_scores(x, g, q, wk, wv, wo, y)) @ (x @ wk) * {sc}", "transpose(d_scores(x, g, q, wk, wv, wo, y)) @ (x @ wk)")
mut("grad_wk forgets the 1/sqrt(d) scale", f"transpose(x) @ (d_scores(x, g, q, wk, wv, wo, y) @ q) * {sc}", "transpose(x) @ (d_scores(x, g, q, wk, wv, wo, y) @ q)")
mut("grad_wv does not weight by the attention (uses the unweighted upstream)", "transpose(x) @ (d_context_rows(x, g, q, wk, wv, wo, y) * reshape(attn_matrix(x, q, wk), 96, 1))", "transpose(x) @ d_context_rows(x, g, q, wk, wv, wo, y)")
mut("d_logits has the wrong sign (y minus p)", "(exp(log_softmax(logits(x, g, q, wk, wv, wo))) - y) * 0.041666666666666664", "(y - exp(log_softmax(logits(x, g, q, wk, wv, wo)))) * 0.041666666666666664")
mut("d_logits is not averaged over the 24 sequences", "(exp(log_softmax(logits(x, g, q, wk, wv, wo))) - y) * 0.041666666666666664", "(exp(log_softmax(logits(x, g, q, wk, wv, wo))) - y)")
mut("grad_wo uses the values instead of the attended context", "transpose(context(x, g, q, wk, wv)) @ d_logits(x, g, q, wk, wv, wo, y)", "transpose(g @ (x @ wv)) @ d_logits(x, g, q, wk, wv, wo, y)")
mut("the attention scores are not scaled by 1/sqrt(d) in the forward pass (the gradient no longer matches)", f"transpose(q) * {sc}, 24, 4))", "transpose(q), 24, 4))")
mut("d_attn_matrix uses the keys instead of the values", "row_sum(d_context_rows(x, g, q, wk, wv, wo, y) * (x @ wv))", "row_sum(d_context_rows(x, g, q, wk, wv, wo, y) * (x @ wk))")
mut("the naive softmax in the attention (no row maximum subtracted)", "def softmax_rows(m: tensor[24x4]) = exp(m - row_max(m)) / row_sum(exp(m - row_max(m)))", "def softmax_rows(m: tensor[24x4]) = exp(m) / row_sum(exp(m))")
print("(The last one is expected to be NOT CAUGHT: the attention scores here stay below about 4 in size, where exp cannot overflow, so the naive formula gives the")
print(" same numbers. Chapters 29 to 32 showed the overflow regime; this chapter's checks do not enter it.)")
