#!/usr/bin/env python3
"""Checks the Mountain Goat bigram trainer against an independent Python trainer, and against facts that must hold whatever the code looks like.
mgc prints six significant digits, so numbers are compared with a relative tolerance of about 1e-5.

  1. TRAINING: the loss at every checkpoint, and the final weights, probabilities and gradient, equal the Python trainer's;
  2. THE LOSS: strictly decreasing at the checkpoints, never below the conditional entropy of the data (no bigram model can beat it), and within 0.002 of it at the end;
  3. WHAT IT LEARNED: the trained probabilities are within 0.01 of the observed frequencies of the next token, for every token that has a next token in the data;
  4. THE UNSEEN ROW: token 4 is never a current token, so its row of weights gets exactly zero gradient, stays exactly 0, and its probabilities stay exactly 0.2;
  5. THE GRADIENT: the hand-derived gradient matches a finite-difference estimate (central differences of the loss, step 0.01) for three random weight matrices;
  6. STRESS: weights of +-1000 (where forming the probabilities and then taking their log would give inf or nan) give the right loss and gradient, with no nan or inf.
Usage: check_bigram.py [path-to-mgc]      Exit status 0 only if every check passes.
"""
import sys, math
import bigram_lib as B
mgc = sys.argv[1] if len(sys.argv) > 1 else None
failures = 0
def report(ok, name, detail=""):
    global failures
    failures += not ok
    print(f"  {'ok  ' if ok else 'FAIL'} {name}" + ("" if ok else f"\n       {detail}"))
def rel_close(a, b, tol=2e-5, floor=1e-9): return all(abs(x - y) <= tol * abs(y) + floor for r, q in zip(a, b) for x, y in zip(r, q))

print("-- training against the independent Python trainer")
got, text = B.run_mg(B.train_program(), mgc)
w_ref, losses = B.train_ref(max(B.CHECKPOINTS))
cp_losses = [g[0][0] for g in got[:len(B.CHECKPOINTS)]]; w_mg, p_mg, g_mg = got[len(B.CHECKPOINTS):]
for k, v in zip(B.CHECKPOINTS, cp_losses):
    report(abs(v - losses[k]) <= 1e-5 * max(1, losses[k]), f"loss after {k} steps equals the reference ({losses[k]:.6f})", f"got {v}")
report(B.close(w_mg, w_ref), f"weights after {max(B.CHECKPOINTS)} steps equal the reference", f"got {w_mg[0]} want {w_ref[0]}")
report(B.close(p_mg, B.probabilities_ref(w_ref)), "probabilities equal the reference", f"got {p_mg[0]}")
report(rel_close(g_mg, B.gradient_ref(w_ref), tol=2e-5, floor=1e-9), "the gradient at the end equals the reference gradient (relative)", f"got {g_mg[0]} want {B.gradient_ref(w_ref)[0]}")
report(all(abs(sum(r) - 1) < 1e-5 for r in p_mg), "each row of probabilities sums to 1", str([sum(r) for r in p_mg]))

print("-- the loss")
report(all(a > b for a, b in zip(cp_losses, cp_losses[1:])), "the loss is strictly decreasing at the checkpoints", str(cp_losses))
report(all(v >= B.ENTROPY - 1e-6 for v in cp_losses), f"the loss never goes below the conditional entropy of the data ({B.ENTROPY:.6f}), the best any bigram model can do", str(cp_losses))
report(cp_losses[-1] - B.ENTROPY < 0.002, f"after {max(B.CHECKPOINTS)} steps the loss is within 0.002 of that bound", f"{cp_losses[-1]} vs {B.ENTROPY}")
report(abs(cp_losses[0] - math.log(B.V)) < 1e-5, f"before training the loss is log(5) = {math.log(B.V):.6f}: every token equally likely", str(cp_losses[0]))

print("-- what it learned")
for i in range(B.V):
    if B.EMPIRICAL[i] is None: continue
    err = max(abs(p - e) for p, e in zip(p_mg[i], B.EMPIRICAL[i]))
    report(err < 0.01, f"token {i}: learned probabilities {[round(p, 3) for p in p_mg[i]]} are within 0.01 of the observed {[round(e, 3) for e in B.EMPIRICAL[i]]}", f"largest difference {err}")

print("-- the unseen row")
report(all(v == 0 for v in w_mg[4]), "token 4 is never a current token: its row of weights is still exactly 0", str(w_mg[4]))
report(all(v == 0 for v in g_mg[4]), "its gradient is exactly 0", str(g_mg[4]))
report(all(abs(v - 0.2) < 1e-6 for v in p_mg[4]), "so its probabilities are exactly uniform (0.2 each)", str(p_mg[4]))

print("-- the gradient against finite differences (central difference of the loss, step 0.01)")
rng = B.__dict__.get("random")
import random
for seed in (1, 2, 3):
    random.seed(seed); w = [[round(random.uniform(-1, 1), 1) for _ in range(B.V)] for _ in range(B.V)]
    out, _ = B.run_mg(B.gradcheck_program(w), mgc)
    analytic, base = out[0], out[1][0][0]; pairs = out[2:]
    numeric = [[(pairs[2 * (i * B.V + j)][0][0] - pairs[2 * (i * B.V + j) + 1][0][0]) / 0.02 for j in range(B.V)] for i in range(B.V)]
    worst = max(abs(analytic[i][j] - numeric[i][j]) for i in range(B.V) for j in range(B.V))
    report(worst < 2e-3, f"random weights #{seed}: largest difference between the gradient and the finite-difference estimate is {worst:.1e}", f"analytic {analytic[0]} numeric {numeric[0]}")
    report(rel_close(analytic, B.gradient_ref(w), tol=2e-5, floor=1e-8) and abs(base - B.loss_ref(w)) < 1e-5, f"random weights #{seed}: gradient and loss equal the reference", f"{analytic[0]} vs {B.gradient_ref(w)[0]}")

print("-- stress: weights of +-1000")
random.seed(9); wbig = [[random.choice([-1000.0, 1000.0]) for _ in range(B.V)] for _ in range(B.V)]
src = B.DEFS + B.data_lets() + f"let w = {B.lit(wbig)}\nprint loss(w, x, y)\nprint gradient(w, x, y)\nprint probabilities(w)\n"
out, text = B.run_mg(src, mgc)
report("nan" not in text and "inf" not in text, "no nan and no inf anywhere in the output", text[:200])
report(abs(out[0][0][0] - B.loss_ref(wbig)) <= 1e-5 * max(1, B.loss_ref(wbig)), f"the loss equals the reference ({B.loss_ref(wbig):.4f})", f"got {out[0]}")
report(rel_close(out[1], B.gradient_ref(wbig), tol=2e-5, floor=1e-8), "the gradient equals the reference", f"got {out[1][0]}")
report(rel_close(out[2], B.probabilities_ref(wbig), tol=2e-5, floor=1e-9), "the probabilities equal the reference (each row is a one-hot-like 0 and 1)", f"got {out[2][0]}")
print("all checks pass" if failures == 0 else f"{failures} CHECK(S) FAILED")
sys.exit(1 if failures else 0)
