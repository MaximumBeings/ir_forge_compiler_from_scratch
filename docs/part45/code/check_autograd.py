#!/usr/bin/env python3
"""Checks autograd.py (Chapter 45):
  1. EVERY RULE, against an independent reference: ten small programs that between them use every operation autograd differentiates; the gradient it generates, compiled and run by mgc, must match central
     finite differences of a plain-Python evaluation of the same program (double precision, so the reference is good to ~1e-9 and the comparison is limited only by the six printed digits: 1e-5);
  2. TIES: a maximum attained twice gives each tied entry half the gradient (hand-worked, since finite differences do not apply at a kink);
  3. THE HAND-DERIVED BACKWARD PASSES OF THE BOOK: Chapter 33's attention classifier (4 gradients), Chapter 34's layer normalisation, and Chapter 35's whole transformer block (16 gradients: embeddings,
     layer norms, attention, feed-forward, output layer): autograd reproduces what those chapters derived by hand, to the six printed digits, on every element;
  4. TRAINING: ten gradient-descent steps on Chapter 33's classifier using only the generated gradients give the loss Chapter 33 recorded after 0, 1, 5 and 10 steps of its hand-derived training;
  5. REFUSALS: a loss that is not 1x1, an unknown name, a loss that does not depend on a matrix, and a rank-3 program are each refused with a message.
Environment variables (CHK_*) change an input; mutation.py edits autograd.py to check that each claim can fail.   Usage: check_autograd.py     Exit status 0 only if all pass."""
import glob, os, subprocess, sys, tempfile
here = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, here)
import common, reference
from common import run_matrices, close
AUTOGRAD = os.environ.get("CHK_AUTOGRAD") or os.path.join(here, "autograd.py"); W = tempfile.mkdtemp(prefix="ch45c_"); failures = 0
def report(ok, name, detail=""):
    global failures; failures += not ok
    print(f"  {'ok  ' if ok else 'FAIL'} {name}" + ("" if ok else f"\n       {detail}"))
def lets(path): return [n for n, _ in __import__("autograd").source_lets(path)]
def autograd(path, names, *extra):
    r = subprocess.run([sys.executable, AUTOGRAD, path, "--wrt", ",".join(names), *extra], capture_output=True, text=True)
    if r.returncode: return None, r.stderr
    out = os.path.join(W, os.path.basename(path)); open(out, "w").write(r.stdout); return out, ""
# ---- 1
print("-- 1. every rule, against finite differences of an independent evaluation")
micro = sorted(glob.glob(os.path.join(here, "examples", "m[01]*.mg"))); micro = [m for m in micro if "m10_ties" not in m]; ok = 0; bad = []; total = 0
for p in micro:
    names = lets(p); prog, err = autograd(p, names)
    if prog is None: bad.append(os.path.basename(p) + ": " + err[:80]); continue
    got = run_matrices(prog); ref = reference.finite_difference(p, names)
    good = len(got) == 1 + len(names) and all(close(got[1 + i], ref[n]) for i, n in enumerate(names))
    ok += good; total += sum(len(r) * len(r[0]) for r in ref.values()); (None if good else bad.append(os.path.basename(p)))
report(ok == len(micro) and not bad, f"all {len(micro)} programs: the generated gradients match finite differences in every one of {total} matrix elements", "; ".join(bad))
# ---- 2
print("-- 2. ties")
t = os.path.join(here, "examples", "m10_ties.mg"); prog, err = autograd(t, ["m"]); got = run_matrices(prog)
report(got[1] == [[0.0, 0.5, 0.5], [0.5, 0.5, 0.0]], "col_sum(row_max(m)) for m = [[1,3,3],[2,2,0]]: the gradient is [[0, .5, .5], [.5, .5, 0]]", str(got[1:]))
# ---- 3
print("-- 3. the hand-derived backward passes of Chapters 33, 34 and 35")
H = [("h33_attention.mg", ["q0", "wk0", "wv0", "wo0"], "Chapter 33's attention classifier"), ("h34_layer_norm.mg", ["h"], "Chapter 34's layer normalisation"),
     ("h35_transformer_step1.mg", ["e0", "g10", "n10", "wq0", "wk0", "wv0", "wo0", "g20", "n20", "w10", "c10", "w20", "c20", "gf0", "nf0", "wu0"], "Chapter 35's transformer block")]
for f, names, label in H:
    p = os.path.join(here, "examples", f); prog, err = autograd(p, names); hand = run_matrices(p); got = run_matrices(prog)
    # the hand program prints: loss, then the hand-derived gradients in the order of `names`; the generated one: loss, then the gradients in the order of `names`
    elements = sum(len(r) * len(r[0]) for r in hand[1:])
    report(len(got) == len(hand) == 1 + len(names) and all(close(g, h) for g, h in zip(got, hand)), f"{label}: loss and {len(names)} gradient matrices ({elements:,} elements) equal the hand-derived ones", f"{len(got)} {len(hand)}")
# ---- 4
print("-- 4. training with the generated gradients")
base = os.path.join(here, "examples", "h33_attention.mg"); prog, err = autograd(base, ["q0", "wk0", "wv0", "wo0"], "--descend", "10", "--lr", "3.0"); mine = [m[0][0] for m in run_matrices(prog)]
ch33 = [m[0][0] for m in run_matrices(os.path.join(here, "..", "..", "part33", "code", "examples", "03_train.mg"))[:8:2]]     # Chapter 33's own hand-derived training: the loss after 0, 1, 5 and 10 steps
report(len(mine) == 11 and all(abs(mine[i] - w) <= 1e-5 * w for i, w in zip((0, 1, 5, 10), ch33)) and all(x > y for x, y in zip(mine, mine[1:])),
       "10 gradient-descent steps (lr 3.0) on Chapter 33's classifier with the GENERATED gradients: loss %s after 0, 1, 5, 10 steps, the same as Chapter 33's hand-derived training (%s); the loss fell at every step" % (" ".join("%.6g" % mine[i] for i in (0, 1, 5, 10)), " ".join("%.6g" % w for w in ch33)), str(mine))
# ---- 5
print("-- 5. refusals")
def refused(src, names, fragment, tag):
    p = os.path.join(W, tag + ".mg"); open(p, "w").write(src); prog, err = autograd(p, names); return prog is None and fragment in err, err.strip()
cases = [("let a = [[1, 2], [3, 4]]\nprint a\n", ["a"], "must be a 1x1 matrix", "not1x1"), ("let a = [[1, 2], [3, 4]]\nprint col_sum(row_sum(a))\n", ["nope"], "no `let nope", "unknown"),
         ("let a = [[1, 2], [3, 4]]\nlet b = [[5, 6], [7, 8]]\nprint col_sum(row_sum(a))\n", ["b"], "does not depend on b", "unused"), ("let a = [[1, 2], [3, 4]]\nprint col_sum(row_sum(ge(a, [[2.5, 2.5]])))\n", ["a"], "does not depend", "flat")]
res = [refused(*c) for c in cases]
report(all(r[0] for r in res), "a non-1x1 loss, an unknown name, an unused matrix and a loss that is flat in a matrix are refused with a message", str([r[1] for r in res if not r[0]]))
r3 = subprocess.run([sys.executable, AUTOGRAD, os.path.join(here, "..", "..", "part28", "code", "examples", [f for f in os.listdir(os.path.join(here, "..", "..", "part28", "code", "examples")) if f.endswith(".mg")][0]), "--wrt", "x"], capture_output=True, text=True)
report(r3.returncode != 0 and r3.stderr.startswith("autograd: ") and "Traceback" not in r3.stderr, "a program that is not rank 2 (Chapter 28's) is refused with a message: " + r3.stderr.strip()[:90].replace("\n", " "))
print("all checks pass" if not failures else f"{failures} CHECK(S) FAILED"); sys.exit(1 if failures else 0)
