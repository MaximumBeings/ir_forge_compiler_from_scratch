#!/usr/bin/env python3
"""Everything needed to build, run and check the Chapter 33 programs: the task, the data, seeded initial weights, an INDEPENDENT Python trainer (per-example
loops; the gradient is derived token by token, not by matrix algebra), and functions that write the Mountain Goat programs, including the definitions
(generated for a given batch size, so the same text serves the 24 training sequences and the 40 held-out ones)."""
import itertools, math, os, re, subprocess, sys, tempfile
here = os.path.dirname(os.path.abspath(__file__))
MGC = os.path.join(here, "..", "..", "part32", "code", "mgc")        # this chapter adds no compiler operation: it uses Chapter 32's compiler
V, N, D, C = 5, 4, 3, 5          # vocabulary, tokens per sequence, attention width, classes (the label is a token, so C = V)
PRIORITY = [1, 3, 2, 0, 4]       # the hidden rule: the label is the token present in the sequence that comes first in this list
LR, STEPS = 3.0, 200
CHECKPOINTS = [0, 1, 5, 10, 25, 50, 100, 200]
SCALE = 1 / math.sqrt(D)
def label(seq): return min(seq, key=PRIORITY.index)

def lcg(seed):
    x = seed
    while True:
        x = (x * 1103515245 + 12345) % (2 ** 31); yield x / 2 ** 31
def sequences(n, seed):
    r = lcg(seed); return [[int(next(r) * V) for _ in range(N)] for _ in range(n)]
TRAIN, TEST = sequences(24, 3), sequences(40, 4)
EVERY = [list(s) for s in itertools.product(range(V), repeat=N)]      # all 625 possible sequences, in a fixed order
CHUNK = 25                                                            # they are checked 25 at a time (a program's shapes are fixed)
CHUNKS = [EVERY[i:i + CHUNK] for i in range(0, len(EVERY), CHUNK)]
def init_params(seed=1, scale=0.5):
    r = lcg(seed)
    def mat(a, b): return [[round((next(r) - 0.5) * 2 * scale, 2) for _ in range(b)] for _ in range(a)]
    return dict(q=mat(1, D), wk=mat(V, D), wv=mat(V, D), wo=mat(D, C))
ORDER = ["q", "wk", "wv", "wo"]

# ---- the independent Python trainer ------------------------------------------------------------------------------------------------------
def softmax(r):
    m = max(r); e = [math.exp(v - m) for v in r]; s = sum(e); return [x / s for x in e]
def forward(p, seq):
    k = [p["wk"][t] for t in seq]; v = [p["wv"][t] for t in seq]
    s = [sum(p["q"][0][j] * k[n][j] for j in range(D)) * SCALE for n in range(N)]
    a = softmax(s); h = [sum(a[n] * v[n][j] for n in range(N)) for j in range(D)]
    lg = [sum(h[j] * p["wo"][j][c] for j in range(D)) for c in range(C)]
    return k, v, s, a, h, lg
def loss_and_gradient(p, data):
    B = len(data); L = 0.0; correct = 0
    g = dict(q=[[0.0] * D], wk=[[0.0] * D for _ in range(V)], wv=[[0.0] * D for _ in range(V)], wo=[[0.0] * C for _ in range(D)])
    for seq in data:
        y = label(seq); k, v, s, a, h, lg = forward(p, seq); pr = softmax(lg)
        L -= math.log(pr[y]) / B; correct += max(range(C), key=lambda c: lg[c]) == y
        dl = [(pr[c] - (1 if c == y else 0)) / B for c in range(C)]
        for j in range(D):
            for c in range(C): g["wo"][j][c] += h[j] * dl[c]
        dh = [sum(dl[c] * p["wo"][j][c] for c in range(C)) for j in range(D)]
        da = [sum(dh[j] * v[n][j] for j in range(D)) for n in range(N)]
        for n in range(N):
            for j in range(D): g["wv"][seq[n]][j] += a[n] * dh[j]
        dsum = sum(a[n] * da[n] for n in range(N)); ds = [a[n] * (da[n] - dsum) for n in range(N)]
        for n in range(N):
            for j in range(D):
                g["q"][0][j] += ds[n] * k[n][j] * SCALE
                g["wk"][seq[n]][j] += ds[n] * p["q"][0][j] * SCALE
    return L, g, correct
def train_ref(steps=STEPS, seed=1):
    p = init_params(seed); hist = {}
    for k in range(steps + 1):
        L, g, c = loss_and_gradient(p, TRAIN); hist[k] = (L, c)
        if k == steps: break
        p = {key: [[w - LR * gw for w, gw in zip(rw, rg)] for rw, rg in zip(p[key], g[key])] for key in p}
    return p, hist
def attention_ref(p, seq): return forward(p, seq)[3]
def token_scores_ref(p): return [sum(p["q"][0][j] * p["wk"][t][j] for j in range(D)) * SCALE for t in range(V)]

# ---- writing the Mountain Goat programs ---------------------------------------------------------------------------------------------------
def lit(m): return "[" + ", ".join("[" + ", ".join(repr(v) if v != int(v) else str(int(v)) for v in row) + "]" for row in m) + "]"
def onehot_rows(data): return [[1 if j == t else 0 for j in range(V)] for seq in data for t in seq]          # (B*N) x V, the tokens of each sequence one after the other
def group_matrix(B): return [[1 if col // N == b else 0 for col in range(B * N)] for b in range(B)]          # B x (B*N): row b adds up the N rows of sequence b
def label_rows(data): return [[1 if j == label(seq) else 0 for j in range(C)] for seq in data]
def defs(B, suffix="", gradients=False):
    BN = B * N; s = suffix; invB = repr(1 / B); sc = repr(SCALE)
    args = f"x: tensor[{BN}x{V}], g: tensor[{B}x{BN}], q: tensor[1x{D}], wk: tensor[{V}x{D}], wv: tensor[{V}x{D}], wo: tensor[{D}x{C}], y: tensor[{B}x{C}]"
    call = "x, g, q, wk, wv, wo, y"
    L = [f"def softmax_rows{s}(m: tensor[{B}x{N}]) = exp(m - row_max(m)) / row_sum(exp(m - row_max(m)))",
         f"def attn_matrix{s}(x: tensor[{BN}x{V}], q: tensor[1x{D}], wk: tensor[{V}x{D}]) = softmax_rows{s}(reshape((x @ wk) @ transpose(q) * {sc}, {B}, {N}))",
         f"def context{s}(x: tensor[{BN}x{V}], g: tensor[{B}x{BN}], q: tensor[1x{D}], wk: tensor[{V}x{D}], wv: tensor[{V}x{D}]) = g @ ((x @ wv) * reshape(attn_matrix{s}(x, q, wk), {BN}, 1))",
         f"def logits{s}(x: tensor[{BN}x{V}], g: tensor[{B}x{BN}], q: tensor[1x{D}], wk: tensor[{V}x{D}], wv: tensor[{V}x{D}], wo: tensor[{D}x{C}]) = context{s}(x, g, q, wk, wv) @ wo",
         f"def log_softmax{s}(z: tensor[{B}x{C}]) = z - row_max(z) - log(row_sum(exp(z - row_max(z))))",
         f"def loss{s}({args}) = col_sum(row_sum(y * log_softmax{s}(logits{s}(x, g, q, wk, wv, wo)))) * -{invB}",
         f"def correct{s}({args}) = col_sum(row_sum(ge(logits{s}(x, g, q, wk, wv, wo), row_max(logits{s}(x, g, q, wk, wv, wo))) * y))"]
    if gradients:
        L += [f"def d_logits({args}) = (exp(log_softmax(logits(x, g, q, wk, wv, wo))) - y) * {invB}",
              f"def grad_wo({args}) = transpose(context(x, g, q, wk, wv)) @ d_logits({call})",
              f"def d_context_rows({args}) = transpose(g) @ (d_logits({call}) @ transpose(wo))",
              f"def grad_wv({args}) = transpose(x) @ (d_context_rows({call}) * reshape(attn_matrix(x, q, wk), {BN}, 1))",
              f"def d_attn_matrix({args}) = reshape(row_sum(d_context_rows({call}) * (x @ wv)), {B}, {N})",
              f"def d_scores({args}) = reshape(attn_matrix(x, q, wk) * (d_attn_matrix({call}) - row_sum(attn_matrix(x, q, wk) * d_attn_matrix({call}))), {BN}, 1)",
              f"def grad_q({args}) = transpose(d_scores({call})) @ (x @ wk) * {sc}",
              f"def grad_wk({args}) = transpose(x) @ (d_scores({call}) @ q) * {sc}"]
    text = "\n".join(L) + "\n"
    old, new = os.environ.get("MG_MUTANT_OLD"), os.environ.get("MG_MUTANT_NEW")          # used by model_mutation.py to test a deliberately wrong backward pass
    return text.replace(old, new) if old else text
COMMENTS = """# One-head attention classifier. A sequence of 4 tokens (one-hot rows) goes in; the label is the token present that ranks first in a hidden priority list.
# B sequences are stacked: x has B*4 rows (the tokens of sequence 0, then sequence 1, ...) and g (B x B*4) adds up the 4 rows belonging to each sequence.
# q (1x3) is the learned query; wk, wv (5x3) turn a token into its key and value; wo (3x5) turns the attended value into scores for the 5 possible labels.
"""
def data_lets(everything=False):
    out = (f"let x = {lit(onehot_rows(TRAIN))}\nlet g = {lit(group_matrix(len(TRAIN)))}\nlet y = {lit(label_rows(TRAIN))}\n"
           f"let xt = {lit(onehot_rows(TEST))}\nlet gt = {lit(group_matrix(len(TEST)))}\nlet yt = {lit(label_rows(TEST))}\n")
    if everything:
        out += f"let gc = {lit(group_matrix(CHUNK))}\n" + "".join(f"let xc{i} = {lit(onehot_rows(c))}\nlet yc{i} = {lit(label_rows(c))}\n" for i, c in enumerate(CHUNKS))
    return out
def train_program(seed=1, steps=STEPS, checkpoints=CHECKPOINTS, d=None):
    p = init_params(seed)
    out = [COMMENTS, d if d is not None else defs(len(TRAIN), "", gradients=True), defs(len(TEST), "_te"), defs(CHUNK, "_ex"), data_lets(everything=True), "let q0 = " + lit(p["q"]), "let wk0 = " + lit(p["wk"]), "let wv0 = " + lit(p["wv"]), "let wo0 = " + lit(p["wo"])]
    for k in range(1, steps + 1):
        a = f"x, g, q{k-1}, wk{k-1}, wv{k-1}, wo{k-1}, y"
        out += [f"let q{k} = q{k-1} - grad_q({a}) * {LR}", f"let wk{k} = wk{k-1} - grad_wk({a}) * {LR}", f"let wv{k} = wv{k-1} - grad_wv({a}) * {LR}", f"let wo{k} = wo{k-1} - grad_wo({a}) * {LR}"]
    for k in checkpoints: out.append(f"print loss(x, g, q{k}, wk{k}, wv{k}, wo{k}, y)\nprint correct(x, g, q{k}, wk{k}, wv{k}, wo{k}, y)")
    f = f"q{steps}, wk{steps}, wv{steps}, wo{steps}"
    out += [f"print q{steps}", f"print wk{steps}", f"print wv{steps}", f"print wo{steps}",
            f"print (wk{steps} @ transpose(q{steps})) * {SCALE!r}",                      # each token's attention score: how strongly a token draws attention
            f"print attn_matrix(x, q{steps}, wk{steps})",                                  # the trained attention weights on the 24 training sequences
            f"print loss_te(xt, gt, {f}, yt)", f"print correct_te(xt, gt, {f}, yt)"]
    out += [f"print correct_ex(xc{i}, gc, {f}, yc{i})" for i in range(len(CHUNKS))]       # how many of each chunk of 25 sequences are right: every sequence there is
    out += [f"print logits_ex(xc{len(CHUNKS) - 1}, gc, q{steps}, wk{steps}, wv{steps}, wo{steps})"]  # the scores of the last chunk (its last row is the sequence 4 4 4 4)
    return "\n".join(out) + "\n"
def gradient_program(p, d=None):
    a = "x, g, q, wk, wv, wo, y"
    out = [COMMENTS, d if d is not None else defs(len(TRAIN), "", gradients=True), data_lets(), "\n".join(f"let {k} = {lit(p[k])}" for k in ORDER), f"print grad_q({a})", f"print grad_wk({a})", f"print grad_wv({a})", f"print grad_wo({a})", f"print loss({a})"]
    eps = 0.01
    for key in ORDER:
        for i in range(len(p[key])):
            for j in range(len(p[key][0])):
                for sign, tag in ((1, "p"), (-1, "m")):
                    rows = [r[:] for r in p[key]]; rows[i][j] = round(rows[i][j] + sign * eps, 10)
                    args = ", ".join(f"{k}{'_' + tag + '_' + str(i) + '_' + str(j) if k == key else ''}" for k in ORDER)
                    out.append(f"let {key}_{tag}_{i}_{j} = {lit(rows)}")
                    out.append(f"print loss(x, g, {args}, y)")
    return "\n".join(out) + "\n"

def run_mg(source, mgc=None):
    mgc = mgc or MGC
    with tempfile.NamedTemporaryFile("w", suffix=".mg", delete=False) as f: f.write(source); path = f.name
    try: r = subprocess.run([mgc, "run", path], capture_output=True, text=True, timeout=1200)
    finally: os.unlink(path)
    if r.returncode != 0: raise RuntimeError(f"mgc failed ({r.returncode}): {r.stderr.strip()[:400]}")
    tensors = []
    for chunk in r.stdout.split("Unranked Memref")[1:]:
        data = chunk.split("data =", 1)[1]
        tensors.append([[float(x) for x in re.findall(r"-?(?:nan|inf|\d+(?:\.\d+)?(?:e[-+]?\d+)?)", row)] for row in re.findall(r"\[([^\[\]]+)\]", data)])
    return tensors, r.stdout
def close(a, b, tol=1e-5):
    return len(a) == len(b) and all(len(r) == len(q) and all(abs(x - y) <= tol * max(1.0, abs(y)) for x, y in zip(r, q)) for r, q in zip(a, b))
