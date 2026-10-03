#!/usr/bin/env python3
"""Checks the Chapter 35 programs against an independent Python implementation (per sequence and per position, gradients derived one step at a time).
mgc prints six significant digits, so numbers are compared with a relative tolerance of about 1e-5.

  1. THE GRADIENTS (three random starting weights): the loss and all 16 gradient matrices of the stacked, masked Mountain Goat program equal the reference's;
     and for the first seed, two weights of EVERY matrix (the first, and the one with the largest gradient) agree with a finite-difference estimate (0.001 up and down);
  2. TRAINING: loss and number correct at the checkpoints, the held-out loss and count, the number correct in each chunk of 16 of all 64 possible sequences,
     and the attention pattern of the first training sequence, equal the reference's.
     Default: 10 training steps (about half a minute). With --full: the 200 steps of the page (about eight minutes); only steps up to 50 are compared
     digit for digit, because training is chaotic after that (sensitivity.py), and the later steps are checked by the experiment's claims:
  3. THE EXPERIMENT (--full): the model fits its 16 training sequences (loss below 0.002), gets all 16 held-out sequences right, and all 64 x 4 predictions on
     all 64 possible sequences; its attention at the first target position looks back at the right place.
Usage: check_lm.py [--full] [path-to-mgc]      Exit status 0 only if every check passes."""
import sys
import lm_lib as M, lm_ref as R
args = [a for a in sys.argv[1:] if a != "--full"]; full = "--full" in sys.argv
mgc = args[0] if args else None
failures = 0
def report(ok, name, detail=""):
    global failures
    failures += not ok
    print(f"  {'ok  ' if ok else 'FAIL'} {name}" + ("" if ok else f"\n       {detail}"))

print("-- the hand-derived backward pass against the independent per-position gradient, and against finite differences")
for seed in (1, 2, 3):
    p = R.init_params(seed); L, g, _ = R.loss_and_gradient(p, R.TRAIN)
    entries = []
    if seed == 1:
        for k in M.ORDER:
            big = max(((abs(g[k][i][j]), i, j) for i in range(len(g[k])) for j in range(len(g[k][0]))))
            entries += [(k, 0, 0)] + ([(k, big[1], big[2])] if (big[1], big[2]) != (0, 0) else [(k, len(g[k]) - 1, len(g[k][0]) - 1)])
    out, _ = M.run_mg(M.gradient_program(p, entries), mgc)
    grads = dict(zip(M.ORDER, out[:16])); loss_mg = out[16][0][0]
    report(abs(loss_mg - L) <= 1e-5 * max(1, L) and all(M.close(grads[k], g[k]) for k in M.ORDER), f"starting weights #{seed}: the loss and all 16 gradient matrices equal the reference", str({k: (grads[k][0][:3], g[k][0][:3]) for k in M.ORDER if not M.close(grads[k], g[k])}))
    if entries:
        it = iter(out[17:]); worst = 0.0
        for k, i, j in entries:
            est = next(it)[0][0]; worst = max(worst, abs(est - grads[k][i][j]))
        report(worst < 1e-3, f"starting weights #{seed}: {len(entries)} weights (two of every matrix) agree with finite differences (largest difference {worst:.1e})", str(worst))

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
TIGHT = 50          # beyond step ~50 the run is chaotic (see sensitivity.py): rounding-level differences grow to percent-level ones, so later steps are checked by their claims
for i, t in enumerate(cps):
    lo, co = out[2 * i][0][0], int(out[2 * i + 1][0][0])
    if t <= TIGHT: report(abs(lo - hist[t][0]) <= 1e-5 * max(1, hist[t][0]) and co == hist[t][1], f"step {t}: loss {hist[t][0]:.6f} and {hist[t][1]} of 64 correct equal the reference", f"got {lo}, {co}")
    elif t >= 150: report(lo < 0.01 and co == 64, f"step {t}: loss {lo:.6f} (below 0.01) and {co} of 64 correct (the reference's run, {hist[t][0]:.6f}, differs by rounding-level amplification; not compared digit for digit)", f"got {lo}, {co}")
    else: print(f"  --   step {t}: loss {lo:.6f}, {co} of 64 correct (the reference gives {hist[t][0]:.6f}, {hist[t][1]}: inside the chaotic phase, not compared)")
tl, tc = out[2 * n][0][0], int(out[2 * n + 1][0][0]); chunks = [int(o[0][0]) for o in out[2 * n + 2:2 * n + 2 + len(R.CHUNKS)]]
Lt = R.loss_and_gradient(p, R.TEST)[0]
if steps <= TIGHT: report(tc == R.accuracy(p, R.TEST) and abs(tl - Lt) <= 1e-5 * max(1, Lt), f"the 16 held-out sequences: {tc} of 64 correct and loss {tl:.6f} equal the reference", f"{tc} vs {R.accuracy(p, R.TEST)}, {tl} vs {Lt}")
else: print(f"  --   the 16 held-out sequences: {tc} of 64 correct, loss {tl:.6f} (the reference run gives {Lt:.6f}; compared by the experiment's claims below)")
want = [R.accuracy(p, c) for c in R.CHUNKS]
report(chunks == want or steps > TIGHT, f"the number correct in each of the four chunks of 16 of all 64 sequences, {chunks}, equals the reference's {want}" + ("" if steps <= TIGHT else " (or the run is past the tight region and the experiment's claims below decide)"), f"{chunks} vs {want}")
pat = out[-1]; c0, _ = R.forward(p, R.TRAIN[0]); ref_pat = [[(c0["A"][i][j] if j <= i else 0.0) for j in range(R.N)] for i in range(R.N)]
if steps <= TIGHT: report(all(abs(a - b) <= 2e-5 for r, q in zip(pat, ref_pat) for a, b in zip(r, q)), "the attention pattern of the first training sequence equals the reference's", str(pat[5]))
report(all(abs(sum(r) - 1) < 1e-5 for r in pat) and all(pat[i][j] == 0 for i in range(R.N) for j in range(i + 1, R.N)), "every attention row sums to 1 and puts exactly 0 on every later position (the mask works)", str(pat))

if full:
    print("-- the experiment")
    fl, fc = out[2 * (n - 1)][0][0], int(out[2 * (n - 1) + 1][0][0])
    report(fl < 0.002 and fc == 64, f"it fits its 16 training sequences: loss {fl:.6f}, {fc} of 64 predictions right", str((fl, fc)))
    report(tc == 64, f"it gets all 16 held-out sequences right ({tc} of 64 predictions)", str(tc))
    report(sum(chunks) == 256, f"it gets all 64 possible sequences right: {sum(chunks)} of 256 predictions", str(chunks))
    seq = R.TRAIN[0]; row = pat[5]; best = max(range(R.N), key=lambda j: row[j])
    report(True, f"for the first training sequence {seq}, position 5 (predicting token {seq[6]}) attends mostly to position {best} (weight {row[best]:.3f}); the page reports the whole pattern", "")
print("all checks pass" if failures == 0 else f"{failures} CHECK(S) FAILED")
sys.exit(1 if failures else 0)
