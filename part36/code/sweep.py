#!/usr/bin/env python3
"""A PYTHON-ONLY experiment (it does not go through mgc): how reliable is training the two-block, two-head model, and how does it compare with Chapter 35's one-block,
one-head model? Uses the independent Python implementations lm2_ref and (Chapter 35's) lm_ref, 200 steps of gradient descent, four starting-weight seeds.
Part A: learning rates for the two-block model, trained on the page's 16 sequences. The score is the number correct of the 192 predictions on the 48 sequences NOT trained on.
Part B: one block against two blocks, trained on 16 sequences and on 32 sequences (the first 32 of the same random order), scored the same way on the sequences not trained on."""
import math
import lm2_ref as R2
import lm_ref as R1
ORDER = R1._order            # the random order of the 64 sequences (Chapter 35); the first 16 are the page's training set
def unseen(train_n): return [R1.EVERY[i] for i in ORDER[train_n:]]
def run(R, lr, seed, train_n):
    data = [R1.EVERY[i] for i in ORDER[:train_n]]; p = R.init_params(seed)
    try:
        for _ in range(200):
            L, g, c = R.loss_and_gradient(p, data)
            if not math.isfinite(L): return None
            p = {k: [[w - lr * gw for w, gw in zip(rw, rg)] for rw, rg in zip(p[k], g[k])] for k in p}
        L, g, c = R.loss_and_gradient(p, data)
        return L, R.accuracy(p, unseen(train_n)), 4 * (64 - train_n)
    except (OverflowError, ValueError, ZeroDivisionError): return None
print("Part A: two blocks, 16 training sequences: per starting-weight seed 1..4: (final training loss, correct of 192 on unseen sequences)")
for lr in (0.25, 0.5, 1.0):
    cells = []
    for seed in range(1, 5):
        r = run(R2, lr, seed, 16); cells.append("diverged" if r is None else f"({r[0]:.3g}, {r[1]})")
    print(f"  lr {lr:>4}   " + "  ".join(cells), flush=True)
print("Part B: one block (lr 1.0) against two blocks (lr 0.5): per seed 1..4: (final training loss, correct on unseen sequences of 192 for 16 training sequences, 128 for 32)")
for train_n in (16, 32):
    for label, R, lr in (("one block ", R1, 1.0), ("two blocks", R2, 0.5)):
        cells = []
        for seed in range(1, 5):
            r = run(R, lr, seed, train_n); cells.append(f"({r[0]:.3g}, {r[1]})")
        print(f"  {train_n} training sequences, {label}   " + "  ".join(cells), flush=True)
