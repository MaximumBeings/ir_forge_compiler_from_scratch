#!/usr/bin/env python3
"""Chapter 46: the largest curvature of Chapter 33's loss with respect to the output matrix wo0, found by POWER ITERATION using only Hessian-vector products from hvp.py (the 15 x 15 Hessian is never
formed), then what it predicts about gradient descent on wo0. Output: curvature_out.txt   (about 4 minutes)
For a quadratic loss, gradient descent with learning rate lr converges when lr < 2 / lambda_max and diverges above it; the classifier's loss is not quadratic, so this is a local guide: the table
at the end runs 30 real steps at several multiples of 2/lambda_max and reports what happened."""
import math, os, subprocess, sys, tempfile
here = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, here)
from common import run_matrices
P = os.path.join(here, "..", "..", "part45", "code", "examples", "h33_attention.mg"); W = tempfile.mkdtemp(prefix="ch46k_"); R, C = 3, 5
def hv(v):
    r = subprocess.run([sys.executable, os.path.join(here, "hvp.py"), P, "--wrt", "wo0", "--vec", str(v)], capture_output=True, text=True, check=True)
    f = os.path.join(W, "hv.mg"); open(f, "w").write(r.stdout); return run_matrices(f)[1]
flat = lambda m: [x for r in m for x in r]; unflat = lambda a: [a[i * C:(i + 1) * C] for i in range(R)]
v = unflat([1.0 + 0.1 * k for k in range(R * C)]); n = math.sqrt(sum(x * x for x in flat(v))); v = unflat([x / n for x in flat(v)]); lam = 0.0
print("power iteration: lambda_k = v . (H v) with v normalised after every step")
for k in range(1, 81):
    w = hv(v); lam_new = sum(a * b for a, b in zip(flat(v), flat(w))); n = math.sqrt(sum(x * x for x in flat(w))); v = unflat([x / n for x in flat(w)])
    if k in (1, 2, 3, 5, 10, 20, 40, 60, 80): print(f"  iteration {k:2d}: lambda = {lam_new:.6f}")
    if abs(lam_new - lam) < 1e-7 * abs(lam_new): print(f"  converged at iteration {k}: lambda = {lam_new:.6f}"); lam = lam_new; break
    lam = lam_new
print("(the run stopped at convergence if a line says so above; otherwise it hit the 80-iteration cap and lambda_max is a lower estimate)")
print(f"largest curvature of the loss along the 15 output weights at the initial point: lambda_max = {lam:.6f}   (2 / lambda_max = {2 / lam:.4f})")
print()
print(f"gradient descent on wo0 only (the other weights fixed), 30 steps, from the initial point; lr as a multiple of 2/lambda_max:")
print(f"{'multiple':>9} {'lr':>8} {'loss at step 0':>15} {'step 1':>10} {'step 10':>10} {'step 30':>10}  loss rose at some step?")
for mult in (0.25, 0.5, 0.9, 1.1, 2.0, 5.0):
    lr = mult * 2 / lam
    r = subprocess.run([sys.executable, os.path.join(here, "autograd.py"), P, "--wrt", "wo0", "--descend", "30", "--lr", repr(lr)], capture_output=True, text=True, check=True)
    f = os.path.join(W, "d.mg"); open(f, "w").write(r.stdout); L = [m[0][0] for m in run_matrices(f)]
    rose = any(b > a for a, b in zip(L, L[1:]))
    print(f"{mult:>9} {lr:>8.3f} {L[0]:>15.6g} {L[1]:>10.6g} {L[10]:>10.6g} {L[30]:>10.6g}  {'yes' if rose else 'no'}", flush=True)
