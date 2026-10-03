#!/usr/bin/env python3
"""A PYTHON-ONLY experiment (it does not go through mgc): how reliable is training model B, and how does it depend on the learning rate and the starting weights?
Uses the independent Python implementation in ffn_lib. For each learning rate and each of six starting-weight seeds, trains for 600 steps and reports the final
training loss and how many of the 81 possible sequences are classified correctly. Model A is run at the chosen learning rate for comparison."""
import math
import ffn_lib as F
def run(model, lr, seed):
    p = F.init_params(model, seed)
    try:
        for _ in range(F.STEPS):
            L, g, c = F.loss_and_gradient(model, p, F.TRAIN)
            if not math.isfinite(L): return None
            p = {k: [[w - lr * gw for w, gw in zip(rw, rg)] for rw, rg in zip(p[k], g[k])] for k in p}
        L, g, c = F.loss_and_gradient(model, p, F.TRAIN)
        return L, sum(F.predict_correct(model, p, s) for s in F.EVERY)
    except (OverflowError, ValueError, ZeroDivisionError): return None
print(f"{'model':>5} {'lr':>5}   per starting-weight seed 1..6: (final training loss, correct of 81)")
for model, lr in [("A", 0.5), ("B", 0.25), ("B", 0.5), ("B", 1.0), ("B", 2.0)]:
    cells = []
    for seed in range(1, 7):
        r = run(model, lr, seed); cells.append("diverged" if r is None else f"({r[0]:.3g}, {r[1]})")
    print(f"{model:>5} {lr:>5}   " + "  ".join(cells))
