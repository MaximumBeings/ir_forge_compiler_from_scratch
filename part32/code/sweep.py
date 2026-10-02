#!/usr/bin/env python3
"""Runs the Mountain Goat trainer for each weight-decay strength and prints a table of the final (step 400) numbers. Every number comes from an mgc run."""
import sys
import generalize_lib as G
mgc = sys.argv[1] if len(sys.argv) > 1 else None
n = len(G.CHECKPOINTS)
print(f"{'strength':>9} {'train loss':>11} {'held-out loss':>14} {'largest |weight|':>17}   held-out loss at steps {G.CHECKPOINTS[1:]}")
for lam in G.LAMBDAS + [G.UNSTABLE]:
    got, _ = G.run_mg(G.train_program(lam), mgc)
    tl = [got[2 * i][0][0] for i in range(n)]; hl = [got[2 * i + 1][0][0] for i in range(n)]
    mx = max(abs(v) for row in got[2 * n] for v in row)
    print(f"{lam:>9} {tl[-1]:>11.4g} {hl[-1]:>14.4g} {mx:>17.4g}   {[float('%.4g' % v) for v in hl[1:]]}" + ("   <- unstable: learning rate x strength is above 2" if lam == G.UNSTABLE else ""))
