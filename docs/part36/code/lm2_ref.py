#!/usr/bin/env python3
"""The INDEPENDENT Python implementation of the Chapter 36 model: Chapter 30's architecture (two blocks, each with two attention heads and a feed-forward network,
pre-norm, residual connections, a final layer norm) as a causal language model, forward and backward, written per sequence and per position with plain lists.
The task and the data are Chapter 35's (imported from its reference)."""
import math, sys, os
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "part35", "code"))
import lm_ref as R1
from lm_ref import V, N, TARGETS, EVERY, TRAIN, TEST, CHUNKS, POS, EPS, lcg, softmax, matvec, ln_forward, ln_backward
D, NH, DH, H, NB = 8, 2, 4, 16, 2          # model width, heads, head width, feed-forward width, blocks
SC = 1 / math.sqrt(DH)
BLOCK_KEYS = ["g1", "bt1", "wq1", "wk1", "wv1", "wo1", "wq2", "wk2", "wv2", "wo2", "g2", "bt2", "w1", "b1", "w2", "b2"]
ORDER = ["emb"] + [f"{k}_{b}" for b in range(1, NB + 1) for k in BLOCK_KEYS] + ["gf", "bf", "wout"]
def init_params(seed=1, scale=0.3):
    r = lcg(seed)
    def mat(a, b, s=scale): return [[round((next(r) - 0.5) * 2 * s, 2) for _ in range(b)] for _ in range(a)]
    p = dict(emb=mat(V, D, 1.0))
    for b in range(1, NB + 1):
        p.update({f"g1_{b}": [[1.0] * D], f"bt1_{b}": [[0.0] * D]})
        for h in (1, 2): p.update({f"wq{h}_{b}": mat(D, DH), f"wk{h}_{b}": mat(D, DH), f"wv{h}_{b}": mat(D, DH), f"wo{h}_{b}": mat(DH, D)})
        p.update({f"g2_{b}": [[1.0] * D], f"bt2_{b}": [[0.0] * D], f"w1_{b}": mat(D, H), f"b1_{b}": [[0.0] * H], f"w2_{b}": mat(H, D), f"b2_{b}": [[0.0] * D]})
    p.update(gf=[[1.0] * D], bf=[[0.0] * D], wout=mat(D, V))
    return {k: p[k] for k in ORDER}
def rows_ln(x, g, b):
    u = []; st = []
    for row in x: o, uh, sig = ln_forward(row, g, b); u.append(o); st.append((uh, sig))
    return u, st
def block_forward(p, b, x):
    W = lambda k: p[f"{k}_{b}"]
    c = dict(x=x); u1, c["ln1"] = rows_ln(x, W("g1"), W("bt1")); c["u1"] = u1
    c["Q"] = {}; c["K"] = {}; c["V"] = {}; c["A"] = {}; c["O"] = {}; att = [[0.0] * D for _ in range(N)]
    for h in (1, 2):
        Q = [matvec(r, W(f"wq{h}")) for r in u1]; K = [matvec(r, W(f"wk{h}")) for r in u1]; Vv = [matvec(r, W(f"wv{h}")) for r in u1]; A = []; O = []
        for i in range(N):
            s = [sum(Q[i][j] * K[k][j] for j in range(DH)) * SC for k in range(i + 1)]       # causal: position i attends to positions 0..i
            a = softmax(s); A.append(a); O.append([sum(a[k] * Vv[k][j] for k in range(i + 1)) for j in range(DH)])
        for i in range(N):
            o = matvec(O[i], W(f"wo{h}")); att[i] = [att[i][j] + o[j] for j in range(D)]
        c["Q"][h], c["K"][h], c["V"][h], c["A"][h], c["O"][h] = Q, K, Vv, A, O
    x1 = [[x[i][j] + att[i][j] for j in range(D)] for i in range(N)]; c["x1"] = x1
    u2, c["ln2"] = rows_ln(x1, W("g2"), W("bt2")); c["u2"] = u2
    pre = [[a + W("b1")[0][m] for m, a in enumerate(matvec(r, W("w1")))] for r in u2]; rl = [[max(0.0, a) for a in r] for r in pre]
    f = [[a + W("b2")[0][j] for j, a in enumerate(matvec(r, W("w2")))] for r in rl]
    c["pre"], c["rl"] = pre, rl
    return [[x1[i][j] + f[i][j] for j in range(D)] for i in range(N)], c
def forward(p, seq):
    x = [[p["emb"][t][j] + POS[i][j] for j in range(D)] for i, t in enumerate(seq)]; caches = []
    for b in range(1, NB + 1): x, c = block_forward(p, b, x); caches.append(c)
    uf, lnf = rows_ln(x, p["gf"], p["bf"]); logits = [matvec(r, p["wout"]) for r in uf]
    return dict(caches=caches, xN=x, uf=uf, lnf=lnf), logits
def block_backward(p, b, c, dx2, g):
    W = lambda k: p[f"{k}_{b}"]; G = lambda k: g[f"{k}_{b}"]
    dx1 = [row[:] for row in dx2]                                   # the residual around the feed-forward network: x2 = x1 + f
    for i in range(N):
        df = dx2[i]
        for j in range(D): G("b2")[0][j] += df[j]
        for m in range(H):
            for j in range(D): G("w2")[m][j] += c["rl"][i][m] * df[j]
        drl = [sum(df[j] * W("w2")[m][j] for j in range(D)) for m in range(H)]
        dpre = [drl[m] if c["pre"][i][m] >= 0 else 0.0 for m in range(H)]
        for m in range(H): G("b1")[0][m] += dpre[m]
        for a in range(D):
            for m in range(H): G("w1")[a][m] += c["u2"][i][a] * dpre[m]
        du2 = [sum(dpre[m] * W("w1")[a][m] for m in range(H)) for a in range(D)]
        uh, sig = c["ln2"][i]
        for j in range(D): G("bt2")[0][j] += du2[j]; G("g2")[0][j] += du2[j] * uh[j]
        dln = ln_backward(du2, uh, sig, W("g2"))
        for j in range(D): dx1[i][j] += dln[j]
    dx0 = [row[:] for row in dx1]                                   # the residual around attention: x1 = x0 + attn
    du1 = [[0.0] * D for _ in range(N)]
    for h in (1, 2):
        dO = [[0.0] * DH for _ in range(N)]
        for i in range(N):
            datt = dx1[i]
            for a in range(DH):
                for j in range(D): G(f"wo{h}")[a][j] += c["O"][h][i][a] * datt[j]
            dO[i] = [sum(datt[j] * W(f"wo{h}")[a][j] for j in range(D)) for a in range(DH)]
        dQ = [[0.0] * DH for _ in range(N)]; dK = [[0.0] * DH for _ in range(N)]; dV = [[0.0] * DH for _ in range(N)]
        for i in range(N):
            a = c["A"][h][i]; dA = [sum(dO[i][j] * c["V"][h][k][j] for j in range(DH)) for k in range(i + 1)]
            for k in range(i + 1):
                for j in range(DH): dV[k][j] += a[k] * dO[i][j]
            dsum = sum(a[k] * dA[k] for k in range(i + 1))
            for k in range(i + 1):
                ds = a[k] * (dA[k] - dsum)
                for j in range(DH): dQ[i][j] += ds * c["K"][h][k][j] * SC; dK[k][j] += ds * c["Q"][h][i][j] * SC
        for i in range(N):
            for a in range(D):
                for j in range(DH):
                    G(f"wq{h}")[a][j] += c["u1"][i][a] * dQ[i][j]; G(f"wk{h}")[a][j] += c["u1"][i][a] * dK[i][j]; G(f"wv{h}")[a][j] += c["u1"][i][a] * dV[i][j]
            for a in range(D):
                du1[i][a] += sum(dQ[i][j] * W(f"wq{h}")[a][j] + dK[i][j] * W(f"wk{h}")[a][j] + dV[i][j] * W(f"wv{h}")[a][j] for j in range(DH))
    for i in range(N):
        uh, sig = c["ln1"][i]
        for j in range(D): G("bt1")[0][j] += du1[i][j]; G("g1")[0][j] += du1[i][j] * uh[j]
        dln = ln_backward(du1[i], uh, sig, W("g1"))
        for j in range(D): dx0[i][j] += dln[j]
    return dx0
def loss_and_gradient(p, data):
    B = len(data); T = len(TARGETS); L = 0.0; correct = 0
    g = {k: [[0.0] * len(v[0]) for _ in v] for k, v in p.items()}
    for seq in data:
        c, logits = forward(p, seq); duf = [[0.0] * D for _ in range(N)]
        for i in TARGETS:
            y = seq[i + 1]; lg = logits[i]; mx = max(lg); L -= (lg[y] - mx - math.log(sum(math.exp(v - mx) for v in lg))) / (B * T); correct += max(range(V), key=lambda k: lg[k]) == y
            pr = softmax(lg); dl = [(pr[k] - (1 if k == y else 0)) / (B * T) for k in range(V)]
            for j in range(D):
                for k in range(V): g["wout"][j][k] += c["uf"][i][j] * dl[k]
            duf[i] = [sum(dl[k] * p["wout"][j][k] for k in range(V)) for j in range(D)]
        dx = [[0.0] * D for _ in range(N)]
        for i in range(N):                                   # final layer norm
            uh, sig = c["lnf"][i]
            for j in range(D): g["bf"][0][j] += duf[i][j]; g["gf"][0][j] += duf[i][j] * uh[j]
            dx[i] = ln_backward(duf[i], uh, sig, p["gf"])
        for b in range(NB, 0, -1): dx = block_backward(p, b, c["caches"][b - 1], dx, g)
        for i in range(N):
            for j in range(D): g["emb"][seq[i]][j] += dx[i][j]
    return L, g, correct
def accuracy(p, data):
    return sum(max(range(V), key=lambda k: forward(p, s)[1][i][k]) == s[i + 1] for s in data for i in TARGETS)
if __name__ == "__main__":
    import time
    lr = float(sys.argv[1]) if len(sys.argv) > 1 else 1.0; steps = int(sys.argv[2]) if len(sys.argv) > 2 else 300
    for seed in (1, 2):
        p = init_params(seed); t0 = time.time()
        for s in range(1, steps + 1):
            L, g, c = loss_and_gradient(p, TRAIN)
            for k in ORDER: p[k] = [[v - lr * d for v, d in zip(r, q)] for r, q in zip(p[k], g[k])]
            if s in (1, 10, 25, 50, 100, 150, 200, 300, 400): print(seed, s, round(L, 5), c, flush=True)
        print("seed", seed, "train", accuracy(p, TRAIN), "test", accuracy(p, TEST), "all", accuracy(p, EVERY), "of 256", round(time.time() - t0), "s")
