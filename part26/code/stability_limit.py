#!/usr/bin/env python3
"""How large can the learning rate be before gradient descent diverges on the chapter's noise-free data?
The loss is quadratic in the parameters, with curvature matrix H = (2/N) x^T x; gradient descent with learning rate lr is stable exactly
when lr < 2 / (largest eigenvalue of H). This reproduces the C++ driver's data (same xorshift generator) and finds that eigenvalue by
power iteration (pure Python, no libraries). Output: stability_limit_out.txt"""
M = (1 << 64) - 1
state = 88172645463325252
def uniform(lo, hi):
    global state
    state ^= (state << 13) & M; state ^= state >> 7; state ^= (state << 17) & M
    return lo + (hi - lo) * ((state >> 11) * (1.0 / 9007199254740992.0))
N, D = 200, 4
X = [[uniform(-1, 1) for _ in range(D - 1)] + [1.0] for _ in range(N)]     # three features and the constant-1 column
H = [[2.0 / N * sum(X[i][a] * X[i][b] for i in range(N)) for b in range(D)] for a in range(D)]
v = [1.0] * D
for _ in range(500):
    w = [sum(H[a][b] * v[b] for b in range(D)) for a in range(D)]
    n = sum(x * x for x in w) ** 0.5; v = [x / n for x in w]
lam = sum(v[a] * sum(H[a][b] * v[b] for b in range(D)) for a in range(D))
print(f"largest curvature of the loss on this data: {lam:.4f}")
print(f"gradient descent is stable only for learning rates below 2 / {lam:.4f} = {2 / lam:.4f}")
for lr in (0.2, 1.2):
    print(f"  learning rate {lr}: {'stable' if lr < 2 / lam else 'diverges'}")
