#!/usr/bin/env python3
"""The INDEPENDENT Python implementation of the Chapter 35 model: a one-block, one-head, causal transformer language model, forward and backward, written
per sequence and per position with plain lists (the gradient derived one step at a time, not as stacked matrix algebra)."""
import itertools, math
V, N, D, H = 4, 7, 8, 16          # vocabulary, sequence length, model width (= head width), feed-forward width
SC = 1 / math.sqrt(D); EPS = 0.00001
TARGETS = range(2, 6)            # the positions whose NEXT token is predictable: x[i+1] = x[i-2] there (the sequence repeats a triple)
def make_sequence(a, b, c): return [a, b, c, a, b, c, a]
EVERY = [make_sequence(a, b, c) for a, b, c in itertools.product(range(V), repeat=3)]       # all 64 possible sequences
def lcg(seed):
    x = seed
    while True:
        x = (x * 1103515245 + 12345) % (2 ** 31); yield x / 2 ** 31
_r = lcg(5); _order = sorted(range(len(EVERY)), key=lambda i: next(_r))
TRAIN = [EVERY[i] for i in _order[:16]]; TEST = [EVERY[i] for i in _order[16:32]]            # 16 to train on, 16 held out (the other 32 are seen only in the exhaustive check)
CHUNKS = [EVERY[i:i + 16] for i in range(0, 64, 16)]
def positions():
    return [[round(math.sin(p / 10000 ** (j - j % 2) / D) if False else (math.sin(p / 10 ** (2 * (j // 2) / D)) if j % 2 == 0 else math.cos(p / 10 ** (2 * (j // 2) / D))), 4) for j in range(D)] for p in range(N)]
POS = positions()
def init_params(seed=1, scale=0.3):
    r = lcg(seed)
    def mat(a, b, s=scale): return [[round((next(r) - 0.5) * 2 * s, 2) for _ in range(b)] for _ in range(a)]
    return dict(emb=mat(V, D, 1.0), g1=[[1.0] * D], bt1=[[0.0] * D], wq=mat(D, D), wk=mat(D, D), wv=mat(D, D), wo=mat(D, D),
                g2=[[1.0] * D], bt2=[[0.0] * D], w1=mat(D, H), b1=[[0.0] * H], w2=mat(H, D), b2=[[0.0] * D], gf=[[1.0] * D], bf=[[0.0] * D], wout=mat(D, V))
ORDER = ["emb", "g1", "bt1", "wq", "wk", "wv", "wo", "g2", "bt2", "w1", "b1", "w2", "b2", "gf", "bf", "wout"]
def softmax(r):
    m = max(r); e = [math.exp(v - m) for v in r]; s = sum(e); return [x / s for x in e]
def matvec(v, W): return [sum(v[i] * W[i][j] for i in range(len(v))) for j in range(len(W[0]))]
def ln_forward(v, g, b):
    mu = sum(v) / len(v); var = sum((x - mu) ** 2 for x in v) / len(v); sig = math.sqrt(var + EPS); uh = [(x - mu) / sig for x in v]
    return [g[0][j] * uh[j] + b[0][j] for j in range(len(v))], uh, sig
def ln_backward(du, uh, sig, g):
    duh = [du[j] * g[0][j] for j in range(len(du))]; m1 = sum(duh) / len(du); m2 = sum(duh[j] * uh[j] for j in range(len(du))) / len(du)
    return [(duh[j] - m1 - uh[j] * m2) / sig for j in range(len(du))]
def forward(p, seq):
    x0 = [[p["emb"][t][j] + POS[i][j] for j in range(D)] for i, t in enumerate(seq)]
    c = dict(x0=x0); u1 = []; ln1 = []
    for row in x0: u, uh, sig = ln_forward(row, p["g1"], p["bt1"]); u1.append(u); ln1.append((uh, sig))
    Q = [matvec(r, p["wq"]) for r in u1]; K = [matvec(r, p["wk"]) for r in u1]; Vv = [matvec(r, p["wv"]) for r in u1]
    A = []; O = []
    for i in range(N):
        s = [sum(Q[i][j] * K[k][j] for j in range(D)) * SC for k in range(i + 1)]      # causal: position i attends to positions 0..i
        a = softmax(s) + [0.0] * (N - i - 1); A.append(a)
        O.append([sum(a[k] * Vv[k][j] for k in range(i + 1)) for j in range(D)])
    att = [matvec(o, p["wo"]) for o in O]
    x1 = [[x0[i][j] + att[i][j] for j in range(D)] for i in range(N)]
    u2 = []; ln2 = []
    for row in x1: u, uh, sig = ln_forward(row, p["g2"], p["bt2"]); u2.append(u); ln2.append((uh, sig))
    pre = [[a + p["b1"][0][m] for m, a in enumerate(matvec(r, p["w1"]))] for r in u2]
    rl = [[max(0.0, a) for a in r] for r in pre]
    f = [[a + p["b2"][0][j] for j, a in enumerate(matvec(r, p["w2"]))] for r in rl]
    x2 = [[x1[i][j] + f[i][j] for j in range(D)] for i in range(N)]
    uf = []; lnf = []
    for row in x2: u, uh, sig = ln_forward(row, p["gf"], p["bf"]); uf.append(u); lnf.append((uh, sig))
    logits = [matvec(r, p["wout"]) for r in uf]
    c.update(u1=u1, ln1=ln1, Q=Q, K=K, V=Vv, A=A, O=O, x1=x1, u2=u2, ln2=ln2, pre=pre, rl=rl, x2=x2, uf=uf, lnf=lnf)
    return c, logits
def loss_and_gradient(p, data):
    B = len(data); T = len(TARGETS); L = 0.0; correct = 0
    g = {k: [[0.0] * len(v[0]) for _ in v] for k, v in p.items()}
    for seq in data:
        c, logits = forward(p, seq)
        dx2 = [[0.0] * D for _ in range(N)]
        duf = [[0.0] * D for _ in range(N)]
        for i in TARGETS:
            y = seq[i + 1]; lg = logits[i]; mx = max(lg); L -= (lg[y] - mx - math.log(sum(math.exp(v - mx) for v in lg))) / (B * T); correct += max(range(V), key=lambda k: lg[k]) == y
            pr = softmax(lg); dl = [(pr[k] - (1 if k == y else 0)) / (B * T) for k in range(V)]
            for j in range(D):
                for k in range(V): g["wout"][j][k] += c["uf"][i][j] * dl[k]
            duf[i] = [sum(dl[k] * p["wout"][j][k] for k in range(V)) for j in range(D)]
        for i in range(N):                                   # final layer norm
            uh, sig = c["lnf"][i]
            for j in range(D): g["bf"][0][j] += duf[i][j]; g["gf"][0][j] += duf[i][j] * uh[j]
            dx2[i] = ln_backward(duf[i], uh, sig, p["gf"])
        dx1 = [row[:] for row in dx2]                                   # the residual around the feed-forward network: x2 = x1 + f
        for i in range(N):
            df = dx2[i]
            for j in range(D): g["b2"][0][j] += df[j]
            for m in range(H):
                for j in range(D): g["w2"][m][j] += c["rl"][i][m] * df[j]
            drl = [sum(df[j] * p["w2"][m][j] for j in range(D)) for m in range(H)]
            dpre = [drl[m] if c["pre"][i][m] >= 0 else 0.0 for m in range(H)]
            for m in range(H): g["b1"][0][m] += dpre[m]
            for a in range(D):
                for m in range(H): g["w1"][a][m] += c["u2"][i][a] * dpre[m]
            du2 = [sum(dpre[m] * p["w1"][a][m] for m in range(H)) for a in range(D)]
            uh, sig = c["ln2"][i]
            for j in range(D): g["bt2"][0][j] += du2[j]; g["g2"][0][j] += du2[j] * uh[j]
            dln = ln_backward(du2, uh, sig, p["g2"])
            for j in range(D): dx1[i][j] += dln[j]
        dx0 = [row[:] for row in dx1]                                   # the residual around attention: x1 = x0 + attn
        dO = [[0.0] * D for _ in range(N)]
        for i in range(N):
            datt = dx1[i]
            for a in range(D):
                for j in range(D): g["wo"][a][j] += c["O"][i][a] * datt[j]
            dO[i] = [sum(datt[j] * p["wo"][a][j] for j in range(D)) for a in range(D)]
        dQ = [[0.0] * D for _ in range(N)]; dK = [[0.0] * D for _ in range(N)]; dV = [[0.0] * D for _ in range(N)]
        for i in range(N):
            a = c["A"][i]
            dA = [sum(dO[i][j] * c["V"][k][j] for j in range(D)) for k in range(i + 1)]
            for k in range(i + 1):
                for j in range(D): dV[k][j] += a[k] * dO[i][j]
            dsum = sum(a[k] * dA[k] for k in range(i + 1))
            for k in range(i + 1):
                ds = a[k] * (dA[k] - dsum)
                for j in range(D): dQ[i][j] += ds * c["K"][k][j] * SC; dK[k][j] += ds * c["Q"][i][j] * SC
        for i in range(N):
            for a in range(D):
                for j in range(D):
                    g["wq"][a][j] += c["u1"][i][a] * dQ[i][j]; g["wk"][a][j] += c["u1"][i][a] * dK[i][j]; g["wv"][a][j] += c["u1"][i][a] * dV[i][j]
            du1 = [sum(dQ[i][j] * p["wq"][a][j] + dK[i][j] * p["wk"][a][j] + dV[i][j] * p["wv"][a][j] for j in range(D)) for a in range(D)]
            uh, sig = c["ln1"][i]
            for j in range(D): g["bt1"][0][j] += du1[j]; g["g1"][0][j] += du1[j] * uh[j]
            dln = ln_backward(du1, uh, sig, p["g1"])
            for j in range(D): dx0[i][j] += dln[j]
            for j in range(D): g["emb"][seq[i]][j] += dx0[i][j]
    return L, g, correct
def accuracy(p, data):
    return sum(max(range(V), key=lambda k: forward(p, s)[1][i][k]) == s[i + 1] for s in data for i in TARGETS)
if __name__ == "__main__":
    import sys
    lr = float(sys.argv[1]) if len(sys.argv) > 1 else 0.5
    for seed in (1, 2):
        p = init_params(seed)
        for step in range(1, 401):
            L, g, c = loss_and_gradient(p, TRAIN)
            p = {k: [[w - lr * gw for w, gw in zip(rw, rg)] for rw, rg in zip(p[k], g[k])] for k in p}
            if step in (1, 10, 50, 100, 200, 400): print(lr, seed, step, round(L, 4), c, "/ 64", "test", accuracy(p, TEST), "/64", "all", accuracy(p, EVERY), "/256", flush=True)
