#!/usr/bin/env python3
"""Everything needed to build, run and check the Chapter 34 programs. The task is "exactly one of the tokens 1 and 2 is present" (XOR of presence).
Two models are compared: A, attention pooling and a linear read-out (Chapter 33's model), and B, the same with a layer normalization, a ReLU feed-forward
network and a residual connection between the pooled vector and the read-out. This file holds the data, seeded weights, an INDEPENDENT Python trainer for both
models (per-example loops, gradient derived element by element), and functions that write the Mountain Goat programs, including the hand-derived backward
pass of model B."""
import itertools, math, os, re, subprocess, sys, tempfile
here = os.path.dirname(os.path.abspath(__file__))
MGC = os.path.join(here, "..", "..", "part32", "code", "mgc")        # this chapter adds no compiler operation: it uses Chapter 32's compiler
V, N, D, H, C = 3, 4, 4, 8, 2
LR, STEPS = 0.5, 600
CHECKPOINTS = [0, 1, 10, 50, 100, 200, 400, 600]
SCALE = 1 / math.sqrt(D)        # exactly 0.5
EPS = 0.00001
def label(seq): return 1 if (1 in seq) != (2 in seq) else 0

def lcg(seed):
    x = seed
    while True:
        x = (x * 1103515245 + 12345) % (2 ** 31); yield x / 2 ** 31
EVERY = [list(s) for s in itertools.product(range(V), repeat=N)]          # all 81 possible sequences, in a fixed order
_r = lcg(11); _order = sorted(range(len(EVERY)), key=lambda i: next(_r))
TRAIN = [EVERY[i] for i in _order[:54]]; TEST = [EVERY[i] for i in _order[54:]]      # 54 to train on, the other 27 held out
CHUNKS = [EVERY[i:i + 27] for i in range(0, 81, 27)]                      # the 81 are also tried 27 at a time (a program's shapes are fixed)
def init_params(model, seed=1, scale=0.5):
    r = lcg(seed)
    def mat(a, b): return [[round((next(r) - 0.5) * 2 * scale, 2) for _ in range(b)] for _ in range(a)]
    p = dict(q=mat(1, D), wk=mat(V, D), wv=mat(V, D))
    if model == "B": p.update(gm=[[1.0] * D], bt=[[0.0] * D], w1=mat(D, H), b1=[[0.0] * H], w2=mat(H, D), b2=[[0.0] * D])
    p["wo"] = mat(D, C)
    return p
ORDER = {"A": ["q", "wk", "wv", "wo"], "B": ["q", "wk", "wv", "gm", "bt", "w1", "b1", "w2", "b2", "wo"]}

# ---- the independent Python implementation --------------------------------------------------------------------------------------------
def softmax(r):
    m = max(r); e = [math.exp(v - m) for v in r]; s = sum(e); return [x / s for x in e]
def forward(model, p, seq):
    k = [p["wk"][t] for t in seq]; v = [p["wv"][t] for t in seq]
    s = [sum(p["q"][0][j] * k[n][j] for j in range(D)) * SCALE for n in range(N)]
    a = softmax(s); h = [sum(a[n] * v[n][j] for n in range(N)) for j in range(D)]
    cache = dict(k=k, v=v, s=s, a=a, h=h)
    if model == "B":
        mu = sum(h) / D; var = sum((x - mu) ** 2 for x in h) / D; sig = math.sqrt(var + EPS); uh = [(x - mu) / sig for x in h]
        u = [p["gm"][0][j] * uh[j] + p["bt"][0][j] for j in range(D)]
        pre = [sum(u[i] * p["w1"][i][m] for i in range(D)) + p["b1"][0][m] for m in range(H)]
        rl = [max(0.0, x) for x in pre]
        f = [sum(rl[m] * p["w2"][m][j] for m in range(H)) + p["b2"][0][j] for j in range(D)]
        z = [h[j] + f[j] for j in range(D)]
        cache.update(sig=sig, uh=uh, u=u, pre=pre, rl=rl, z=z)
    else: cache["z"] = h
    z = cache["z"]; lg = [sum(z[j] * p["wo"][j][c] for j in range(D)) for c in range(C)]
    return cache, lg
def loss_and_gradient(model, p, data):
    B = len(data); L = 0.0; correct = 0
    g = {k: [[0.0] * len(v[0]) for _ in v] for k, v in p.items()}
    for seq in data:
        y = label(seq); c, lg = forward(model, p, seq); pr = softmax(lg); mx = max(lg)
        L -= (lg[y] - mx - math.log(sum(math.exp(v - mx) for v in lg))) / B; correct += max(range(C), key=lambda i: lg[i]) == y
        dl = [(pr[i] - (1 if i == y else 0)) / B for i in range(C)]; z = c["z"]
        for j in range(D):
            for i in range(C): g["wo"][j][i] += z[j] * dl[i]
        dz = [sum(dl[i] * p["wo"][j][i] for i in range(C)) for j in range(D)]
        if model == "B":
            for j in range(D): g["b2"][0][j] += dz[j]
            for m in range(H):
                for j in range(D): g["w2"][m][j] += c["rl"][m] * dz[j]
            drl = [sum(dz[j] * p["w2"][m][j] for j in range(D)) for m in range(H)]
            dpre = [drl[m] if c["pre"][m] >= 0 else 0.0 for m in range(H)]                       # relu: the gradient passes where the input is >= 0
            for m in range(H): g["b1"][0][m] += dpre[m]
            for i in range(D):
                for m in range(H): g["w1"][i][m] += c["u"][i] * dpre[m]
            du = [sum(dpre[m] * p["w1"][i][m] for m in range(H)) for i in range(D)]
            for j in range(D): g["bt"][0][j] += du[j]; g["gm"][0][j] += du[j] * c["uh"][j]
            duh = [du[j] * p["gm"][0][j] for j in range(D)]
            m1 = sum(duh) / D; m2 = sum(duh[j] * c["uh"][j] for j in range(D)) / D
            dh = [dz[j] + (duh[j] - m1 - c["uh"][j] * m2) / c["sig"] for j in range(D)]            # the residual path plus the layer-norm path
        else: dh = dz
        a, v, k = c["a"], c["v"], c["k"]
        da = [sum(dh[j] * v[n][j] for j in range(D)) for n in range(N)]
        for n in range(N):
            for j in range(D): g["wv"][seq[n]][j] += a[n] * dh[j]
        dsum = sum(a[n] * da[n] for n in range(N)); ds = [a[n] * (da[n] - dsum) for n in range(N)]
        for n in range(N):
            for j in range(D):
                g["q"][0][j] += ds[n] * k[n][j] * SCALE; g["wk"][seq[n]][j] += ds[n] * p["q"][0][j] * SCALE
    return L, g, correct
def predict_correct(model, p, seq): return max(range(C), key=lambda i: forward(model, p, seq)[1][i]) == label(seq)
def train_ref(model, steps=STEPS, seed=1):
    p = init_params(model, seed); hist = {}
    for k in range(steps + 1):
        L, g, c = loss_and_gradient(model, p, TRAIN); hist[k] = (L, c)
        if k == steps: break
        p = {key: [[w - LR * gw for w, gw in zip(rw, rg)] for rw, rg in zip(p[key], g[key])] for key in p}
    return p, hist

# ---- writing the Mountain Goat programs ---------------------------------------------------------------------------------------------------
def lit(m): return "[" + ", ".join("[" + ", ".join(repr(v) if v != int(v) else str(int(v)) for v in row) + "]" for row in m) + "]"
def onehot_rows(data): return [[1 if j == t else 0 for j in range(V)] for seq in data for t in seq]
def group_matrix(B): return [[1 if col // N == b else 0 for col in range(B * N)] for b in range(B)]
def label_rows(data): return [[1 if j == label(seq) else 0 for j in range(C)] for seq in data]
def defs(model, B, s="", grads=False):
    BN = B * N; sc = repr(SCALE); invB = repr(1 / B)
    P = {"x": f"tensor[{BN}x{V}]", "g": f"tensor[{B}x{BN}]", "q": f"tensor[1x{D}]", "wk": f"tensor[{V}x{D}]", "wv": f"tensor[{V}x{D}]", "gm": f"tensor[1x{D}]", "bt": f"tensor[1x{D}]",
         "w1": f"tensor[{D}x{H}]", "b1": f"tensor[1x{H}]", "w2": f"tensor[{H}x{D}]", "b2": f"tensor[1x{D}]", "wo": f"tensor[{D}x{C}]", "y": f"tensor[{B}x{C}]"}
    names = (["x", "g", "q", "wk", "wv"] + (["gm", "bt", "w1", "b1", "w2", "b2"] if model == "B" else []) + ["wo", "y"])
    sig = lambda ns: ", ".join(f"{n}: {P[n]}" for n in ns); call = lambda ns: ", ".join(ns)
    pool = ["x", "g", "q", "wk", "wv"]; blk = pool + (["gm", "bt", "w1", "b1", "w2", "b2"] if model == "B" else []); full = blk + ["wo"]
    L = [f"def softmax_rows{s}(m: tensor[{B}x{N}]) = exp(m - row_max(m)) / row_sum(exp(m - row_max(m)))",
         f"def attn_matrix{s}({sig(['x', 'q', 'wk'])}) = softmax_rows{s}(reshape((x @ wk) @ transpose(q) * {sc}, {B}, {N}))",
         f"def pooled{s}({sig(pool)}) = g @ ((x @ wv) * reshape(attn_matrix{s}(x, q, wk), {BN}, 1))"]
    if model == "B":
        L += [f"def ln_sigma{s}(h: tensor[{B}x{D}]) = sqrt(row_mean((h - row_mean(h)) * (h - row_mean(h))) + {EPS!r})",
              f"def ln_hat{s}(h: tensor[{B}x{D}]) = (h - row_mean(h)) / ln_sigma{s}(h)",
              f"def ln_out{s}(h: tensor[{B}x{D}], gm: {P['gm']}, bt: {P['bt']}) = ln_hat{s}(h) * gm + bt",
              f"def hidden_pre{s}(h: tensor[{B}x{D}], gm: {P['gm']}, bt: {P['bt']}, w1: {P['w1']}, b1: {P['b1']}) = ln_out{s}(h, gm, bt) @ w1 + b1",
              f"def block{s}({sig(blk)}) = pooled{s}(x, g, q, wk, wv) + (relu(hidden_pre{s}(pooled{s}(x, g, q, wk, wv), gm, bt, w1, b1)) @ w2 + b2)"]
    else:
        L += [f"def block{s}({sig(blk)}) = pooled{s}(x, g, q, wk, wv)"]
    L += [f"def logits{s}({sig(full)}) = block{s}({call(blk)}) @ wo",
          f"def log_softmax{s}(z: tensor[{B}x{C}]) = z - row_max(z) - log(row_sum(exp(z - row_max(z))))",
          f"def loss{s}({sig(names)}) = col_sum(row_sum(y * log_softmax{s}(logits{s}({call(full)})))) * -{invB}",
          f"def correct{s}({sig(names)}) = col_sum(row_sum(ge(logits{s}({call(full)}), row_max(logits{s}({call(full)}))) * y))"]
    if grads:
        a = sig(names); c = call(names); cf = call(full)
        L += [f"def d_logits({a}) = (exp(log_softmax(logits({cf}))) - y) * {invB}",
              f"def grad_wo({a}) = transpose(block({call(blk)})) @ d_logits({c})",
              f"def d_z({a}) = d_logits({c}) @ transpose(wo)"]
        if model == "B":
            h = f"pooled(x, g, q, wk, wv)"
            L += [f"def grad_b2({a}) = col_sum(d_z({c}))",
                  f"def grad_w2({a}) = transpose(relu(hidden_pre({h}, gm, bt, w1, b1))) @ d_z({c})",
                  f"def d_pre({a}) = (d_z({c}) @ transpose(w2)) * ge(hidden_pre({h}, gm, bt, w1, b1), [[0]])",
                  f"def grad_b1({a}) = col_sum(d_pre({c}))",
                  f"def grad_w1({a}) = transpose(ln_out({h}, gm, bt)) @ d_pre({c})",
                  f"def d_u({a}) = d_pre({c}) @ transpose(w1)",
                  f"def grad_bt({a}) = col_sum(d_u({c}))",
                  f"def grad_gm({a}) = col_sum(d_u({c}) * ln_hat({h}))",
                  f"def d_hat({a}) = d_u({c}) * gm",
                  f"def d_h({a}) = d_z({c}) + (d_hat({c}) - row_mean(d_hat({c})) - ln_hat({h}) * row_mean(d_hat({c}) * ln_hat({h}))) / ln_sigma({h})"]
            dh = "d_h"
        else: dh = "d_z"
        L += [f"def d_ctx_rows({a}) = transpose(g) @ {dh}({c})",
              f"def grad_wv({a}) = transpose(x) @ (d_ctx_rows({c}) * reshape(attn_matrix(x, q, wk), {BN}, 1))",
              f"def d_attn_matrix({a}) = reshape(row_sum(d_ctx_rows({c}) * (x @ wv)), {B}, {N})",
              f"def d_scores({a}) = reshape(attn_matrix(x, q, wk) * (d_attn_matrix({c}) - row_sum(attn_matrix(x, q, wk) * d_attn_matrix({c}))), {BN}, 1)",
              f"def grad_q({a}) = transpose(d_scores({c})) @ (x @ wk) * {sc}",
              f"def grad_wk({a}) = transpose(x) @ (d_scores({c}) @ q) * {sc}"]
    text = "\n".join(L) + "\n"
    old, new = os.environ.get("MG_MUTANT_OLD"), os.environ.get("MG_MUTANT_NEW")          # used by model_mutation.py to test a deliberately wrong backward pass
    return text.replace(old, new) if old else text
def comments(model): return ("# " + ("Model B: attention pooling, then a layer normalization, a ReLU feed-forward network and a residual connection, then a linear read-out.\n" if model == "B"
                                      else "Model A: attention pooling and a linear read-out (no layer normalization, feed-forward network or residual connection).\n")
                             + "# B sequences are stacked: x has B*4 rows (the tokens of sequence 0, then sequence 1, ...) and g (B x B*4) adds up the 4 rows belonging to each sequence.\n")
def data_lets():
    out = f"let x = {lit(onehot_rows(TRAIN))}\nlet g = {lit(group_matrix(len(TRAIN)))}\nlet y = {lit(label_rows(TRAIN))}\n"
    out += f"let xt = {lit(onehot_rows(TEST))}\nlet gt = {lit(group_matrix(27))}\nlet yt = {lit(label_rows(TEST))}\n"
    out += "".join(f"let xc{i} = {lit(onehot_rows(c))}\nlet yc{i} = {lit(label_rows(c))}\n" for i, c in enumerate(CHUNKS))
    return out
def train_program(model, seed=1, steps=STEPS, checkpoints=CHECKPOINTS, lr=LR, d=None):
    p = init_params(model, seed); order = ORDER[model]
    out = [comments(model), d if d is not None else defs(model, len(TRAIN), "", grads=True), defs(model, 27, "_27"), data_lets()]
    out += [f"let {k}0 = {lit(p[k])}" for k in order]
    for t in range(1, steps + 1):
        a = ", ".join(["x", "g"] + [f"{k}{t - 1}" for k in order] + ["y"])
        out += [f"let {k}{t} = {k}{t - 1} - grad_{k}({a}) * {lr}" for k in order]
    tup = lambda t: ", ".join(f"{k}{t}" for k in order)
    for t in checkpoints: out.append(f"print loss(x, g, {tup(t)}, y)\nprint correct(x, g, {tup(t)}, y)")
    f = tup(steps)
    out += [f"print loss_27(xt, gt, {f}, yt)", f"print correct_27(xt, gt, {f}, yt)"]
    out += [f"print correct_27(xc{i}, gt, {f}, yc{i})" for i in range(len(CHUNKS))]
    out += [f"print logits_27(xc0, gt, {f})"]                       # the scores of the first chunk of 27 (its first row is the sequence 0 0 0 0)
    return "\n".join(out) + "\n"
def gradient_program(model, p, d=None, eps=0.001):
    order = ORDER[model]; a = ", ".join(["x", "g"] + order + ["y"])
    out = [comments(model), d if d is not None else defs(model, len(TRAIN), "", grads=True), data_lets(), "\n".join(f"let {k} = {lit(p[k])}" for k in order)]
    out += [f"print grad_{k}({a})" for k in order] + [f"print loss({a})"]
    for key in order:
        for i in range(len(p[key])):
            for j in range(len(p[key][0])):
                for sign, tag in ((1, "p"), (-1, "m")):
                    rows = [r[:] for r in p[key]]; rows[i][j] = round(rows[i][j] + sign * eps, 10)
                    args = ", ".join(f"{k}{'_' + tag + '_' + str(i) + '_' + str(j) if k == key else ''}" for k in order)
                    out += [f"let {key}_{tag}_{i}_{j} = {lit(rows)}", f"print loss(x, g, {args}, y)"]
    return "\n".join(out) + "\n"

def run_mg(source, mgc=None):
    mgc = mgc or MGC
    with tempfile.NamedTemporaryFile("w", suffix=".mg", delete=False) as f: f.write(source); path = f.name
    try: r = subprocess.run([mgc, "run", path], capture_output=True, text=True, timeout=3000)
    finally: os.unlink(path)
    if r.returncode != 0: raise RuntimeError(f"mgc failed ({r.returncode}): {r.stderr.strip()[:400]}")
    tensors = []
    for chunk in r.stdout.split("Unranked Memref")[1:]:
        data = chunk.split("data =", 1)[1]
        tensors.append([[float(x) for x in re.findall(r"-?(?:nan|inf|\d+(?:\.\d+)?(?:e[-+]?\d+)?)", row)] for row in re.findall(r"\[([^\[\]]+)\]", data)])
    return tensors, r.stdout
def close(a, b, tol=1e-5):
    return len(a) == len(b) and all(len(r) == len(q) and all(abs(x - y) <= tol * max(1.0, abs(y)) for x, y in zip(r, q)) for r, q in zip(a, b))
