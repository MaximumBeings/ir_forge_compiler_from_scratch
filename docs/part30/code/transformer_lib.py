#!/usr/bin/env python3
"""Everything needed to build, run and check the Chapter 30 transformer: the Mountain Goat definitions (transformer.mg.defs), seeded weights, an
independent Python reference that uses only plain lists and math.exp/math.sqrt, and a function that writes a complete .mg program."""
import math, os, re, subprocess, tempfile
here = os.path.dirname(os.path.abspath(__file__))
DEFS = open(os.environ.get("MG_DEFS_FILE") or os.path.join(here, "transformer.mg.defs")).read()   # MG_DEFS_FILE: used by model_mutation.py to test a deliberately wrong model
N, D, H, V, HEADS = 4, 4, 8, 5, 2          # tokens, model width, feed-forward width, vocabulary, heads (each of width D // HEADS)
MASK = [[0 if j <= i else -1000000000 for j in range(N)] for i in range(N)]
ZERO_MASK = [[0] * N for _ in range(N)]

# ---- plain-list linear algebra ------------------------------------------------------------------------------------------------------
def mm(a, b): return [[sum(a[i][k] * b[k][j] for k in range(len(b))) for j in range(len(b[0]))] for i in range(len(a))]
def tr(a): return [list(r) for r in zip(*a)]
def add(a, b): return [[x + y for x, y in zip(r, q)] for r, q in zip(a, b)]
def addrow(a, b): return [[x + y for x, y in zip(r, b[0])] for r in a]            # a (n x m) plus a 1 x m row, stretched down the rows
def scale(a, c): return [[x * c for x in r] for r in a]

# ---- seeded weights --------------------------------------------------------------------------------------------------------------------
def lcg(seed):
    x = seed
    while True:
        x = (x * 1103515245 + 12345) % (2 ** 31); yield x / 2 ** 31
def mat(rng, r, c, lo=-0.8, hi=0.8): return [[round(lo + (hi - lo) * next(rng), 2) for _ in range(c)] for _ in range(r)]

def make_weights(seed=1):
    rng = lcg(seed); w = {"emb": mat(rng, V, D, -1, 1), "wout": mat(rng, D, V), "gf": [[round(1 + 0.2 * (next(rng) - .5), 2) for _ in range(D)]], "bf": mat(rng, 1, D, -.1, .1)}
    for k in (1, 2):
        w[f"g1_{k}"] = [[round(1 + 0.2 * (next(rng) - .5), 2) for _ in range(D)]]; w[f"bt1_{k}"] = mat(rng, 1, D, -.1, .1)
        for h in (1, 2):
            w[f"wq{h}_{k}"] = mat(rng, D, D // HEADS); w[f"wk{h}_{k}"] = mat(rng, D, D // HEADS); w[f"wv{h}_{k}"] = mat(rng, D, D // HEADS); w[f"wo{h}_{k}"] = mat(rng, D // HEADS, D)
        w[f"g2_{k}"] = [[round(1 + 0.2 * (next(rng) - .5), 2) for _ in range(D)]]; w[f"bt2_{k}"] = mat(rng, 1, D, -.1, .1)
        w[f"w1_{k}"] = mat(rng, D, H); w[f"b1_{k}"] = mat(rng, 1, H, -.1, .1); w[f"w2_{k}"] = mat(rng, H, D); w[f"b2_{k}"] = mat(rng, 1, D, -.1, .1)
    return w

def positions():
    return [[round(math.sin(p / 10000 ** (i / D)) if j % 2 == 0 else math.cos(p / 10000 ** (i / D)), 4) for j in range(D) for i in [j - j % 2]] for p in range(N)]

# ---- the independent Python reference ------------------------------------------------------------------------------------------------
def softmax_ref(s):
    out = []
    for row in s:
        m = max(row); e = [math.exp(v - m) for v in row]; t = sum(e); out.append([v / t for v in e])
    return out
def layer_norm_ref(x, g, b, eps=0.00001):
    out = []
    for row in x:
        mean = sum(row) / len(row); var = sum((v - mean) ** 2 for v in row) / len(row)
        out.append([(v - mean) / math.sqrt(var + eps) * g[0][j] + b[0][j] for j, v in enumerate(row)])
    return out
def head_ref(x, wq, wk, wv, mask):
    s = scale(mm(mm(x, wq), tr(mm(x, wk))), 0.7071067811865476)
    return mm(softmax_ref(add(s, mask)), mm(x, wv))
def forward_ref(w, tokens, mask=MASK, use_positions=True):
    onehot = [[1.0 if j == t else 0.0 for j in range(V)] for t in tokens]
    x = mm(onehot, w["emb"])
    if use_positions: x = add(x, positions())
    stages = {"embedded": x}
    for k in (1, 2):
        ln = layer_norm_ref(x, w[f"g1_{k}"], w[f"bt1_{k}"])
        att = add(mm(head_ref(ln, w[f"wq1_{k}"], w[f"wk1_{k}"], w[f"wv1_{k}"], mask), w[f"wo1_{k}"]), mm(head_ref(ln, w[f"wq2_{k}"], w[f"wk2_{k}"], w[f"wv2_{k}"], mask), w[f"wo2_{k}"]))
        x = add(x, att)
        ln = layer_norm_ref(x, w[f"g2_{k}"], w[f"bt2_{k}"])
        hid = [[max(0.0, v) for v in row] for row in addrow(mm(ln, w[f"w1_{k}"]), w[f"b1_{k}"])]
        x = add(x, addrow(mm(hid, w[f"w2_{k}"]), w[f"b2_{k}"]))
        stages[f"block{k}"] = x
    stages["probs"] = softmax_ref(mm(layer_norm_ref(x, w["gf"], w["bf"]), w["wout"]))
    return stages

# ---- writing the Mountain Goat program --------------------------------------------------------------------------------------------------
def lit(m): return "[" + ", ".join("[" + ", ".join(repr(v) if v != int(v) else str(int(v)) for v in row) + "]" for row in m) + "]"

def program(w, tokens, mask=MASK, use_positions=True, prints=("embedded", "block1", "block2", "probs"), defs=None):
    out = [defs if defs is not None else DEFS]
    for name, m in w.items(): out.append(f"let {name} = {lit(m)}")
    out.append(f"let mask = {lit(mask)}")
    out.append(f"let onehot = {lit([[1 if j == t else 0 for j in range(V)] for t in tokens])}       # the token ids {list(tokens)} as one-hot rows")
    out.append(f"let positions = {lit(positions())}")
    out.append("let x0 = onehot @ emb" + (" + positions" if use_positions else ""))
    prev = "x0"
    for k in (1, 2):
        out.append(f"let a{k} = attention_sublayer({prev}, mask, g1_{k}, bt1_{k}, wq1_{k}, wk1_{k}, wv1_{k}, wo1_{k}, wq2_{k}, wk2_{k}, wv2_{k}, wo2_{k})")
        out.append(f"let y{k} = ffn_sublayer(a{k}, g2_{k}, bt2_{k}, w1_{k}, b1_{k}, w2_{k}, b2_{k})")
        prev = f"y{k}"
    out.append("let probs = softmax_vocab(layer_norm(y2, gf, bf) @ wout)")
    shown = {"embedded": "x0", "block1": "y1", "block2": "y2", "probs": "probs"}
    for p in prints: out.append(f"print {shown[p]}")
    return "\n".join(out) + "\n"

def run_mg(source, mgc=None):
    mgc = mgc or os.path.join(here, "mgc")
    with tempfile.NamedTemporaryFile("w", suffix=".mg", delete=False) as f: f.write(source); path = f.name
    try: r = subprocess.run([mgc, "run", path], capture_output=True, text=True, timeout=300)
    finally: os.unlink(path)
    if r.returncode != 0: raise RuntimeError(f"mgc failed ({r.returncode}): {r.stderr.strip()[:400]}")
    tensors = []
    for chunk in r.stdout.split("Unranked Memref")[1:]:
        data = chunk.split("data =", 1)[1]
        tensors.append([[float(x) for x in re.findall(r"-?(?:nan|inf|\d+(?:\.\d+)?(?:e[-+]?\d+)?)", row)] for row in re.findall(r"\[([^\[\]]+)\]", data)])
    return tensors, r.stdout

def close(a, b, tol=1e-5):
    return len(a) == len(b) and all(len(r) == len(q) and all(abs(x - y) <= tol * max(1.0, abs(y)) for x, y in zip(r, q)) for r, q in zip(a, b))
