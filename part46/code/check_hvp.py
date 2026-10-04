#!/usr/bin/env python3
"""Checks hvp.py (Chapter 46): Hessian-vector products from differentiating the generated backward pass.
  1. Eight small programs, against the FULL Hessian from four-point central differences of the loss in plain Python (reference.py's evaluator, step 1e-4, error ~1e-8 relative):
     H v from the compiled double-differentiated program must match (the Hessian matrix times v) for three different directions v each.
  2. SYMMETRY: v' H w == w' H v, computed with the compiled programs (a property the Hessian has and a wrong rule would break).
  3. THE LOSS PRINT: the program's first print is sum(g * v); it must equal the directional derivative of the loss along v (finite difference of the loss).
  4. Chapter 33's classifier: H v for its output matrix wo0 (15 parameters), against the four-point finite-difference Hessian.
Env CHK_AUTOGRAD points at the autograd.py to test; mutation.py breaks it and expects failures."""
import glob, itertools, os, subprocess, sys, tempfile
here = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, here)
import common, reference
from common import run_matrices, close
HVP = os.path.join(here, "hvp.py"); W = tempfile.mkdtemp(prefix="ch46c_"); failures = 0
AG = os.environ.get("CHK_AUTOGRAD")
def report(ok, name, detail=""):
    global failures; failures += not ok
    print(f"  {'ok  ' if ok else 'FAIL'} {name}" + ("" if ok else f"\n       {detail}"))
def lit(m): return "[" + ", ".join("[" + ", ".join(repr(x) for x in r) + "]" for r in m) + "]"
def hvp(path, name, v):
    env = dict(os.environ); 
    if AG: env["CH46_AUTOGRAD"] = AG
    r = subprocess.run([sys.executable, HVP, path, "--wrt", name, "--vec", lit(v)], capture_output=True, text=True, env=env)
    if r.returncode: raise RuntimeError(r.stderr[:300])
    p = os.path.join(W, "hvp_%s_%d.mg" % (os.path.basename(path), abs(hash(lit(v))) % 10**8)); open(p, "w").write(r.stdout); m = run_matrices(p); return m[0][0][0], m[1]
def fd_hessian(path, name, h=1e-4):
    import autograd as A
    text = subprocess.run([A.MGC, "mlir", path], capture_output=True, text=True).stdout; ops = A.flatten(A.parse(text)); loss = [o for o in ops if o.op == "print"][0].args[0]
    found = A.name_constants(ops, A.source_lets(path)); c = next(o for o in ops if o.res == found[name]); base = [[float(x) for x in r] for r in c.attrs["data"]]; R, C = len(base), len(base[0])
    def L(i, j, di, k, l, dk):
        m = [r[:] for r in base]; m[i][j] += di; m[k][l] += dk; return reference.evaluate(ops, loss, {c.res: m})[0][0]
    n = R * C; H = [[0.0] * n for _ in range(n)]
    for a in range(n):
        for b in range(a, n):
            i, j, k, l = a // C, a % C, b // C, b % C
            H[a][b] = H[b][a] = (L(i, j, h, k, l, h) - L(i, j, h, k, l, -h) - L(i, j, -h, k, l, h) + L(i, j, -h, k, l, -h)) / (4 * h * h)
    return H, (R, C), ops, loss, c, base
def apply(H, v, shape):
    flat = [x for r in v for x in r]; out = [sum(H[a][b] * flat[b] for b in range(len(flat))) for a in range(len(flat))]; return [out[i * shape[1]:(i + 1) * shape[1]] for i in range(shape[0])]
def directions(shape, seed):
    import random; rr = random.Random(seed); return [[[round(rr.uniform(-1, 1), 3) for _ in range(shape[1])] for _ in range(shape[0])] for _ in range(3)]
print("-- 1-3. eight small programs: H v, symmetry and the directional derivative")
progs = [("s01_cubic.mg", "x"), ("s02_matmul_tanhish.mg", "a"), ("s03_softmax_ce.mg", "z"), ("s04_layer_norm.mg", "h"), ("s05_division_log_sqrt.mg", "p"), ("s06_relu_square.mg", "x"), ("s07_relu_exp.mg", "x"), ("s08_reshape_square.mg", "a")]
n_ok = 0; n_elems = 0; bad = []; sym_ok = True; dir_ok = True
for f, name in progs:
    p = os.path.join(here, "examples", f); H, shape, ops, loss, c, base = fd_hessian(p, name); vs = directions(shape, len(f)); results = []
    for v in vs:
        got_loss, got = hvp(p, name, v); want = apply(H, v, shape); results.append((v, got)); n_elems += shape[0] * shape[1]
        if not close(got, want, rel=1e-5, absolute=1e-6): bad.append(f)
        # 3: sum(g * v) = directional derivative of the loss along v (central difference)
        h = 1e-6; up = [[base[i][j] + h * v[i][j] for j in range(shape[1])] for i in range(shape[0])]; dn = [[base[i][j] - h * v[i][j] for j in range(shape[1])] for i in range(shape[0])]
        fd = (reference.evaluate(ops, loss, {c.res: up})[0][0] - reference.evaluate(ops, loss, {c.res: dn})[0][0]) / (2 * h)
        dir_ok &= abs(got_loss - fd) <= 1e-5 * max(abs(fd), 1e-3)
    (v1, h1), (v2, h2) = results[0], results[1]; a_ = sum(x * y for r, s in zip(v2, h1) for x, y in zip(r, s)); b_ = sum(x * y for r, s in zip(v1, h2) for x, y in zip(r, s))
    terms = sum(abs(x * y) for r, s in zip(v2, h1) for x, y in zip(r, s))        # the printed entries carry six digits each, so the sums agree to about 1e-5 of the sum of absolute terms
    sym_ok &= abs(a_ - b_) <= 2e-5 * max(terms, 1e-3)
report(not bad, f"all {len(progs)} programs x 3 directions: H v from the compiled double-differentiated program equals H (four-point finite differences) times v, in every one of {n_elems} elements", str(bad))
report(sym_ok, "symmetry: w' (H v) = v' (H w) for every program (computed with two compiled programs)")
report(dir_ok, "the program's first print, sum(g * v), equals the finite-difference directional derivative of the loss along v")
print("-- 4. Chapter 33's classifier, output matrix wo0 (15 parameters)")
p33 = os.path.join(here, "..", "..", "part45", "code", "examples", "h33_attention.mg"); H, shape, *_ = fd_hessian(p33, "wo0", h=1e-3); v = directions(shape, 33)[0]
got_loss, got = hvp(p33, "wo0", v); want = apply(H, v, shape)
report(close(got, want, rel=1e-4, absolute=1e-5), "H v for Chapter 33's wo0 (3x5) equals the finite-difference Hessian times v to 1e-4 (step 1e-3 limits that reference)", str(got) + " vs " + str(want))
print("-- 5. several matrices at once: the blocks BETWEEN matrices")
def joint(path, names, vs):
    import autograd as A
    text = subprocess.run([A.MGC, "mlir", path], capture_output=True, text=True).stdout; ops = A.flatten(A.parse(text)); loss = [o for o in ops if o.op == "print"][0].args[0]
    found = A.name_constants(ops, A.source_lets(path)); cs = [next(o for o in ops if o.res == found[n]) for n in names]; bases = [[[float(x) for x in r] for r in c.attrs["data"]] for c in cs]
    cells = [(k, i, j) for k, b in enumerate(bases) for i in range(len(b)) for j in range(len(b[0]))]; h = 1e-4
    def L(shifts):
        ms = [[r[:] for r in b] for b in bases]
        for (k, i, j), d in shifts: ms[k][i][j] += d
        return reference.evaluate(ops, loss, {c.res: m for c, m in zip(cs, ms)})[0][0]
    n = len(cells); H = [[0.0] * n for _ in range(n)]
    for p in range(n):
        for q in range(p, n):
            H[p][q] = H[q][p] = (L([(cells[p], h), (cells[q], h)]) - L([(cells[p], h), (cells[q], -h)]) - L([(cells[p], -h), (cells[q], h)]) + L([(cells[p], -h), (cells[q], -h)])) / (4 * h * h)
    flat = [vs[k][i][j] for k, i, j in cells]; hv = [sum(H[p][q] * flat[q] for q in range(n)) for p in range(n)]
    out = [[[0.0] * len(b[0]) for _ in b] for b in bases]
    for p, (k, i, j) in enumerate(cells): out[k][i][j] = hv[p]
    return out
sp = os.path.join(here, "examples", "s02_matmul_tanhish.mg"); vs = [directions((2, 3), 7)[0], directions((3, 2), 8)[0]]
env = dict(os.environ)
if AG: env["CH46_AUTOGRAD"] = AG
r = subprocess.run([sys.executable, HVP, sp, "--wrt", "a,b", "--vec", ";".join(lit(v) for v in vs)], capture_output=True, text=True, env=env); jp = os.path.join(W, "joint.mg"); open(jp, "w").write(r.stdout); m = run_matrices(jp)
want = joint(sp, ["a", "b"], vs)
report(len(m) == 3 and close(m[1], want[0], rel=1e-5, absolute=1e-6) and close(m[2], want[1], rel=1e-5, absolute=1e-6), "wrt a and b together: both blocks of H (v_a, v_b), cross terms included, equal the finite-difference Hessian over all 12 parameters times (v_a, v_b)", str(m[1:]) + " vs " + str(want))
r0 = subprocess.run([sys.executable, HVP, sp, "--wrt", "a,b", "--vec", lit(vs[0])], capture_output=True, text=True, env=env)
report(r0.returncode != 0 and "2 names but 1 direction" in r0.stderr, "a missing direction matrix is refused with a message")
print("all checks pass" if not failures else f"{failures} CHECK(S) FAILED"); sys.exit(1 if failures else 0)
