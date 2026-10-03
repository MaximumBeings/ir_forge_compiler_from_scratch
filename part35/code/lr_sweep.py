#!/usr/bin/env python3
"""A PYTHON-ONLY experiment (it does not go through mgc): how reliable is training the language model, and how does it depend on the learning rate and the
starting weights? Uses the independent Python implementation in lm_ref. For each learning rate and each of four starting-weight seeds, trains for 200 steps (the
page's budget) and reports the final training loss and how many of the 256 predictions (64 possible sequences x 4 target positions) are right."""
import math
import lm_ref as R
STEPS = 200
def run(lr, seed):
    p = R.init_params(seed)
    try:
        for _ in range(STEPS):
            L, g, c = R.loss_and_gradient(p, R.TRAIN)
            if not math.isfinite(L): return None
            p = {k: [[w - lr * gw for w, gw in zip(rw, rg)] for rw, rg in zip(p[k], g[k])] for k in p}
        L, g, c = R.loss_and_gradient(p, R.TRAIN)
        return L, R.accuracy(p, R.EVERY)
    except (OverflowError, ValueError, ZeroDivisionError): return None
print(f"{'lr':>5}   per starting-weight seed 1..4: (final training loss, correct of 256)")
for lr in (0.25, 0.5, 1.0, 2.0):
    cells = []
    for seed in range(1, 5):
        r = run(lr, seed); cells.append("diverged" if r is None else f"({r[0]:.3g}, {r[1]})")
    print(f"{lr:>5}   " + "  ".join(cells), flush=True)
