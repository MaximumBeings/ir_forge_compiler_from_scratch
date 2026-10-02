#!/usr/bin/env python3
"""READ THIS FIRST: this script writes WRONG versions of the trainer (generalize.mg.defs.in with one mistake each) and runs check_generalize.py on each. A "caught" line
(the checker reported FAIL, or the program did not even compile) is the EXPECTED, wanted result: it shows the checker can notice that mistake. "NOT CAUGHT"
means the checker cannot tell the wrong trainer from the right one (reported honestly). Output: model_mutation_out.txt"""
import os, subprocess, sys
here = os.path.dirname(os.path.abspath(__file__)); work = os.path.join(here, "work", "model_mut"); os.makedirs(work, exist_ok=True)
good = open(os.path.join(here, "generalize.mg.defs.in")).read()
print("NOTE: this script deliberately runs wrong trainers. 'caught' lines are EXPECTED: they show the checker can detect the mistake.")
def check(defs_text, label):
    path = os.path.join(work, "mutant.defs"); open(path, "w").write(defs_text)
    r = subprocess.run([sys.executable, os.path.join(here, "check_generalize.py")], capture_output=True, text=True, env=dict(os.environ, MG_DEFS_FILE=path), timeout=900)
    fails = [l.strip()[5:].strip() for l in r.stdout.split("\n") if l.strip().startswith("FAIL")]
    if r.returncode != 0 and not fails: print(f"{label}: caught (the program did not even run: {(r.stderr or r.stdout).strip().splitlines()[-1][:110]})"); return
    if fails:
        kinds = []
        for f in fails:
            k = ("the reference" if "reference" in f else "overfitting/weight decay" if ("held-out" in f or "strength" in f or "weights" in f) else "finite differences" if "gradient" in f else "generation" if ("token" in f or "generation" in f) else "other")
            if k not in kinds: kinds.append(k)
        print(f"{label}: caught by {len(fails)} failing checks ({', '.join(kinds)})")
    else: print(f"{label}: NOT CAUGHT")
out = subprocess.run([sys.executable, os.path.join(here, "check_generalize.py")], capture_output=True, text=True).stdout
print("baseline (nothing broken):", "checker passes (expected)" if "all checks pass" in out else "UNEXPECTED FAILURE")
def mut(label, old, new):
    if old not in good: print(f"{label}: MUTATION DID NOT APPLY"); return
    check(good.replace(old, new, 1), label)
mut("weight decay pushes the weights AWAY from 0 (wrong sign)", "+ w * @LAMBDA@", "- w * @LAMBDA@")
mut("weight decay is missing from the gradient", " + w * @LAMBDA@\n", "\n")
mut("weight decay is applied twice as strongly", "+ w * @LAMBDA@", "+ w * @LAMBDA@ * 2")
mut("the training gradient is not averaged over the 10 pairs", "* 0.1 + w * @LAMBDA@", "+ w * @LAMBDA@")
mut("the held-out loss is averaged over 10, not 4", "* -0.25", "* -0.1")
mut("the held-out surprise has the wrong sign", "yv * log_softmax4(xv @ w)) * -1", "yv * log_softmax4(xv @ w)) * 1")
mut("the penalty in the objective is lambda, not lambda/2 (the gradient no longer matches it)", "* @HALF_LAMBDA@", "* @LAMBDA@")
mut("the learning rate is 4, not 8", "gradient(w, x, y) * 8", "gradient(w, x, y) * 4")
mut("greedy generation compares the maximum with the row, the wrong way round", "ge(x @ p, row_max(x @ p))", "ge(row_max(x @ p), x @ p)")
mut("greedy generation picks the LEAST likely token", "ge(x @ p, row_max(x @ p))", "ge(-(x @ p), row_max(-(x @ p)))")
mut("the training log-softmax is the naive one (no maximum subtracted)", "def log_softmax10(s: tensor[10x5]) = s - row_max(s) - log(row_sum(exp(s - row_max(s))))", "def log_softmax10(s: tensor[10x5]) = s - log(row_sum(exp(s)))")
print("(The last one is caught only because of the deliberately diverging run (strength 0.3): its weights reach 1e58, where a naive log-sum-exp overflows. At the")
print(" weights of the other runs, which stay below 7, the naive formula gives the same numbers, as Chapter 31 showed; I expected it to go uncaught here and was wrong.)")
