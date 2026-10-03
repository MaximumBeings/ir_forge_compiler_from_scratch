#!/usr/bin/env python3
"""A PYTHON-ONLY experiment: how sensitive is the training run to rounding-level differences? Trains the language model twice with the independent Python
implementation: once from the starting weights, once with ONE starting weight (wq[0][0]) nudged by 1e-12 (far smaller than the six digits mgc prints, and about
the size of the differences between two correct implementations' rounding). Reports the training and held-out loss at several steps."""
import lm_ref as R
def train(eps):
    p = R.init_params(1); p["wq"][0][0] += eps; out = {}
    for t in range(201):
        if t in (0, 25, 50, 60, 70, 75, 80, 90, 100, 125, 150, 200): out[t] = (R.loss_and_gradient(p, R.TRAIN)[0], R.loss_and_gradient(p, R.TEST)[0])
        if t < 200:
            L, g, _ = R.loss_and_gradient(p, R.TRAIN)
            for k in R.ORDER: p[k] = [[v - 1.0 * d for v, d in zip(r, q)] for r, q in zip(p[k], g[k])]
    return out
a = train(0.0); b = train(1e-12)
print(f"{'step':>5}  {'train loss':>11} {'nudged by 1e-12':>16}   {'held-out loss':>13} {'nudged':>10}")
for t in a: print(f"{t:>5}  {a[t][0]:>11.6f} {b[t][0]:>16.6f}   {a[t][1]:>13.6f} {b[t][1]:>10.6f}")
