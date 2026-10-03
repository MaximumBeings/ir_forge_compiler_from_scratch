#!/usr/bin/env python3
"""Checks the Chapter 36 programs (two blocks, two heads each) against an independent Python implementation (per sequence and per position, gradients derived one
step at a time). mgc prints six significant digits, so numbers are compared with a relative tolerance of about 1e-5.

  1. THE GRADIENTS (three random starting weights): the loss and all 36 gradient matrices of the stacked, masked Mountain Goat program equal the reference's;
     and for the first seed, the weight with the largest gradient in EVERY matrix (36 weights) agrees with a finite-difference estimate (0.001 up and down);
  2. TRAINING: loss and number correct at the checkpoints, the held-out loss and count, the number correct in each chunk of 16 of all 64 possible sequences, and the
     four attention patterns of the first training sequence, equal the reference's. Default: 10 training steps. With --full: the 200 steps of the page; every checkpoint is compared digit for digit (unlike Chapter 35, this run is not chaotic: sensitivity.py);
  3. THE EXPERIMENT (--full): the model fits its 16 training sequences (loss below 0.01, 64 of 64), and the page's numbers for the held-out and all-sequence scores hold.
  --lean (used by model_mutation.py): seed 1 only, finite differences for six weights, 10 training steps.
Usage: check_lm2.py [--full] [--lean] [path-to-mgc]      Exit status 0 only if every check passes."""
import sys
import lm2_lib as M, lm2_ref as R
args = [a for a in sys.argv[1:] if not a.startswith("--")]; full = "--full" in sys.argv; lean = "--lean" in sys.argv
mgc = args[0] if args else None
failures = 0
def report(ok, name, detail=""):
    global failures
    failures += not ok
    print(f"  {'ok  ' if ok else 'FAIL'} {name}" + ("" if ok else f"\n       {detail}"))
NK = len(M.ORDER)
print("-- the hand-derived backward pass against the independent per-position gradient, and against finite differences")
for seed in ((1,) if lean else (1, 2, 3)):
    p = R.init_params(seed); L, g, _ = R.loss_and_gradient(p, R.TRAIN); entries = []
    if seed == 1:
        keys = ["wq1_1", "wo2_2", "w1_1", "g2_2", "emb", "wout"] if lean else M.ORDER
        for k in keys:
            big = max(((abs(g[k][i][j]), i, j) for i in range(len(g[k])) for j in range(len(g[k][0])))); entries.append((k, big[1], big[2]))
    out, _ = M.run_mg(M.gradient_program(p, entries), mgc)
    grads = dict(zip(M.ORDER, out[:NK])); loss_mg = out[NK][0][0]
    report(abs(loss_mg - L) <= 1e-5 * max(1, L) and all(M.close(grads[k], g[k]) for k in M.ORDER), f"starting weights #{seed}: the loss and all {NK} gradient matrices equal the reference", str([k for k in M.ORDER if not M.close(grads[k], g[k])]))
    if entries:
        it = iter(out[NK + 1:]); worst = 0.0
        for k, i, j in entries: est = next(it)[0][0]; worst = max(worst, abs(est - grads[k][i][j]))
        report(worst < 1e-3, f"starting weights #{seed}: {len(entries)} weights (the largest gradient in {'each of six matrices' if lean else 'every matrix'}) agree with finite differences (largest difference {worst:.1e}{'; at this size of gradient that means all six printed digits agree' if worst == 0 else ''})", str(worst))

steps, cps = (M.STEPS, M.CHECKPOINTS) if full else (10, [0, 1, 10])
print(f"-- training {steps} steps against the independent Python trainer")
out, text = M.run_mg(M.train_program(steps=steps, checkpoints=cps), mgc)
p = R.init_params(1); hist = {}
for t in range(steps + 1):
    if t in cps: hist[t] = (R.loss_and_gradient(p, R.TRAIN)[0], R.accuracy(p, R.TRAIN))
    if t < steps:
        L, g, _ = R.loss_and_gradient(p, R.TRAIN)
        for k in M.ORDER: p[k] = [[v - M.LR * d for v, d in zip(r, q)] for r, q in zip(p[k], g[k])]
n = len(cps)
TIGHT = 200         # unlike Chapter 35's model, this run is NOT chaotic (sensitivity.py: a 1e-12 nudge changes nothing visible in 200 steps), so every checkpoint is compared digit for digit
for i, t in enumerate(cps):
    lo, co = out[2 * i][0][0], int(out[2 * i + 1][0][0])
    if t <= TIGHT: report(abs(lo - hist[t][0]) <= 1e-5 * max(1, hist[t][0]) and co == hist[t][1], f"step {t}: loss {hist[t][0]:.6f} and {hist[t][1]} of 64 correct equal the reference", f"got {lo}, {co}")
    elif t >= 150: report(lo < 0.05 and co == 64, f"step {t}: loss {lo:.6f} (below 0.05) and {co} of 64 correct (the reference's run, {hist[t][0]:.6f}, is not compared digit for digit)", f"got {lo}, {co}")
    else: print(f"  --   step {t}: loss {lo:.6f}, {co} of 64 correct (the reference gives {hist[t][0]:.6f}, {hist[t][1]}: not compared)")
tl, tc = out[2 * n][0][0], int(out[2 * n + 1][0][0]); chunks = [int(o[0][0]) for o in out[2 * n + 2:2 * n + 2 + len(R.CHUNKS)]]
Lt = R.loss_and_gradient(p, R.TEST)[0]
if steps <= TIGHT or not full: report(tc == R.accuracy(p, R.TEST) and abs(tl - Lt) <= 1e-5 * max(1, Lt), f"the 16 held-out sequences: {tc} of 64 correct and loss {tl:.6f} equal the reference", f"{tc} vs {R.accuracy(p, R.TEST)}, {tl} vs {Lt}")
else: print(f"  --   the 16 held-out sequences: {tc} of 64 correct, loss {tl:.6f} (the reference run gives {Lt:.6f}, {R.accuracy(p, R.TEST)} of 64; not compared)")
want = [R.accuracy(p, c) for c in R.CHUNKS]
report(chunks == want, f"the number correct in each of the four chunks of 16 of all 64 sequences, {chunks}, equals the reference's {want}", f"{chunks} vs {want}")
pats = out[2 * n + 2 + len(R.CHUNKS):]
report(len(pats) == 4, "four attention patterns were printed (2 blocks x 2 heads)", str(len(pats)))
if True:
    c0, _ = R.forward(p, R.TRAIN[0]); ok = True
    for idx, (b, h) in enumerate([(1, 1), (1, 2), (2, 1), (2, 2)]):
        ref_pat = [[(c0["caches"][b - 1]["A"][h][i][j] if j <= i else 0.0) for j in range(R.N)] for i in range(R.N)]
        ok &= all(abs(a - r) <= 2e-5 for row, q in zip(pats[idx], ref_pat) for a, r in zip(row, q))
    report(ok, "the four attention patterns of the first training sequence equal the reference's", str(pats[0][5]))
report(all(abs(sum(r) - 1) < 1e-5 for P in pats for r in P) and all(P[i][j] == 0 for P in pats for i in range(R.N) for j in range(i + 1, R.N)), "every attention row of every head sums to 1 and puts exactly 0 on every later position (the mask works)", str(pats))

if full:
    print("-- the experiment")
    fl, fc = out[2 * (n - 1)][0][0], int(out[2 * (n - 1) + 1][0][0])
    report(fl < 0.01 and fc == 64, f"it fits its 16 training sequences: loss {fl:.6f}, {fc} of 64 predictions right", str((fl, fc)))
    print(f"  --   held-out: {tc} of 64 predictions right; all 64 sequences: {sum(chunks)} of 256 right (reported on the page, not asserted)")
print("all checks pass" if failures == 0 else f"{failures} CHECK(S) FAILED")
sys.exit(1 if failures else 0)
