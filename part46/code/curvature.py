#!/usr/bin/env python3
"""Chapter 46: the largest curvature of Chapter 33's loss, found by POWER ITERATION using only Hessian-vector products from hvp.py (the Hessian is never formed), then what it predicts about gradient descent.
Part 1: with respect to the output matrix wo0 alone (15 parameters). Part 2: with respect to ALL FOUR trainable matrices q0, wk0, wv0, wo0 together (48 parameters, cross-matrix blocks included),
the problem Chapter 33 actually trains at learning rate 3.0. Output: curvature_out.txt   (about 15 minutes)
For a quadratic loss, gradient descent with learning rate lr converges when lr < 2 / lambda_max and diverges above it; the classifier's loss is not quadratic, so this is a local guide: the tables run 30
real steps at several multiples of 2/lambda_max and report what happened."""
import math, os, subprocess, sys, tempfile
here = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, here)
from common import run_matrices
P = os.path.join(here, "..", "..", "part45", "code", "examples", "h33_attention.mg"); W = tempfile.mkdtemp(prefix="ch46k_")
SHAPES = {"q0": (1, 3), "wk0": (5, 3), "wv0": (5, 3), "wo0": (3, 5)}
def study(names, label, cap, tag):
    shapes = [SHAPES[n] for n in names]; size = sum(r * c for r, c in shapes)
    def split(flat):
        out = []; k = 0
        for r, c in shapes: out.append([flat[k + i * c:k + (i + 1) * c] for i in range(r)]); k += r * c
        return out
    flat = lambda ms: [x for m in ms for row in m for x in row]
    def hv(v):
        r = subprocess.run([sys.executable, os.path.join(here, "hvp.py"), P, "--wrt", ",".join(names), "--vec", ";".join(str(m) for m in split(v))], capture_output=True, text=True, check=True)
        f = os.path.join(W, "hv.mg"); open(f, "w").write(r.stdout); return flat(run_matrices(f)[1:])
    v = [1.0 + 0.1 * k for k in range(size)]; n = math.sqrt(sum(x * x for x in v)); v = [x / n for x in v]; lam = 0.0; converged = False
    print(f"=== {label}: {size} parameters ===\npower iteration: lambda_k = v . (H v) with v normalised after every step")
    for k in range(1, cap + 1):
        w = hv(v); lam_new = sum(a * b for a, b in zip(v, w)); n = math.sqrt(sum(x * x for x in w)); v = [x / n for x in w]
        if k in (1, 2, 3, 5, 10, 20, 40, 60, 80, 120, 160) or k == cap: print(f"  iteration {k:3d}: lambda = {lam_new:.6f}", flush=True)
        if abs(lam_new - lam) < 1e-7 * abs(lam_new): print(f"  converged at iteration {k}: lambda = {lam_new:.6f}"); converged = True; lam = lam_new; break
        lam = lam_new
    print(("converged" if converged else f"NOT converged after {cap} iterations (a lower estimate)") + f": lambda_max = {lam:.6f}   (2 / lambda_max = {2 / lam:.4f})\n")
    print(f"gradient descent on {', '.join(names)}, 30 steps, from the initial point; lr as a multiple of 2/lambda_max:")
    print(f"{'multiple':>9} {'lr':>8} {'loss at step 0':>15} {'step 1':>10} {'step 10':>10} {'step 30':>10}  loss rose at some step?")
    for mult in (0.25, 0.5, 0.9, 1.1, 2.0, 5.0):
        lr = mult * 2 / lam
        r = subprocess.run([sys.executable, os.path.join(here, "autograd.py"), P, "--wrt", ",".join(names), "--descend", "30", "--lr", repr(lr)], capture_output=True, text=True, check=True)
        f = os.path.join(W, "d.mg"); open(f, "w").write(r.stdout); L = [m[0][0] for m in run_matrices(f)]
        print(f"{mult:>9} {lr:>8.3f} {L[0]:>15.6g} {L[1]:>10.6g} {L[10]:>10.6g} {L[30]:>10.6g}  {'yes' if any(b > a for a, b in zip(L, L[1:])) else 'no'}", flush=True)
    print()
study(["wo0"], "output matrix wo0 alone", 80, "a")
study(["q0", "wk0", "wv0", "wo0"], "all four trainable matrices together (what Chapter 33 trains)", 80, "b")
