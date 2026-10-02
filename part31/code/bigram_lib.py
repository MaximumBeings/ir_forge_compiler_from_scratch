#!/usr/bin/env python3
"""Everything needed to build, run and check the Chapter 31 bigram model: the Mountain Goat definitions (bigram.mg.defs), the data, an INDEPENDENT Python
trainer (plain lists, math.exp and math.log, gradient written from the definition of each step), and functions that write complete .mg programs."""
import math, os, re, subprocess, tempfile
here = os.path.dirname(os.path.abspath(__file__))
DEFS = open(os.environ.get("MG_DEFS_FILE") or os.path.join(here, "bigram.mg.defs")).read()   # MG_DEFS_FILE: used by model_mutation.py to test a wrong model
V = 5
TOKENS = [0, 1, 2, 0, 1, 3, 0, 1, 2, 0, 2, 3, 0, 1, 4]          # a 15-token text over the five tokens 0..4: 14 (current, next) pairs
PAIRS = list(zip(TOKENS[:-1], TOKENS[1:])); T = len(PAIRS)
LR = 8.0
CHECKPOINTS = [0, 1, 2, 5, 10, 25, 50, 100, 200, 400]
X = [[1 if j == a else 0 for j in range(V)] for a, _ in PAIRS]
Y = [[1 if j == b else 0 for j in range(V)] for _, b in PAIRS]
COUNTS = [[sum(1 for a, b in PAIRS if a == i and b == j) for j in range(V)] for i in range(V)]
EMPIRICAL = [[c / sum(row) for c in row] if sum(row) else None for row in COUNTS]           # the observed chance of each next token (None: token 4 is never a current token)
ENTROPY = -sum(COUNTS[a][b] * math.log(COUNTS[a][b] / sum(COUNTS[a])) for a in range(V) for b in range(V) if COUNTS[a][b]) / T   # the lowest loss any bigram model can reach

# ---- the independent Python trainer ------------------------------------------------------------------------------------------------------
def softmax_row(r):
    m = max(r); e = [math.exp(v - m) for v in r]; s = sum(e); return [v / s for v in e]
def log_softmax_row(r):                      # log-sum-exp form: it works when a probability would underflow to 0, where log(softmax) would not
    m = max(r); lse = m + math.log(sum(math.exp(v - m) for v in r)); return [v - lse for v in r]
def loss_ref(w):
    return -sum(log_softmax_row(w[a])[b] for a, b in PAIRS) / T
def gradient_ref(w):
    g = [[0.0] * V for _ in range(V)]
    for a, b in PAIRS:                       # the pair (a, b) pushes row a of w toward token b: dL/dw[a][j] += (p_j - [j == b]) / T
        p = softmax_row(w[a])
        for j in range(V): g[a][j] += (p[j] - (1 if j == b else 0)) / T
    return g
def train_ref(steps, lr=LR):
    w = [[0.0] * V for _ in range(V)]; losses = {0: loss_ref(w)}
    for k in range(1, steps + 1):
        g = gradient_ref(w)
        w = [[w[i][j] - lr * g[i][j] for j in range(V)] for i in range(V)]
        losses[k] = loss_ref(w)
    return w, losses
def probabilities_ref(w): return [softmax_row(r) for r in w]

# ---- writing the Mountain Goat programs ---------------------------------------------------------------------------------------------------
def lit(m): return "[" + ", ".join("[" + ", ".join(repr(v) if v != int(v) else str(int(v)) for v in row) + "]" for row in m) + "]"
def data_lets(): return f"let x = {lit(X)}      # the current tokens {[a for a, _ in PAIRS]}, one-hot\nlet y = {lit(Y)}      # the next tokens {[b for _, b in PAIRS]}, one-hot\n"
def train_program(defs=None, checkpoints=CHECKPOINTS):
    out = [defs if defs is not None else DEFS, data_lets(), f"let w0 = {lit([[0] * V for _ in range(V)])}      # start from all zeros: every token equally likely to follow every token"]
    last = max(checkpoints)
    for k in range(1, last + 1): out.append(f"let w{k} = step(w{k - 1}, x, y)")
    for k in checkpoints: out.append(f"print loss(w{k}, x, y)       # the loss after {k} steps")
    out += [f"print w{last}", f"print probabilities(w{last})", f"print gradient(w{last}, x, y)"]
    return "\n".join(out) + "\n"
def gradcheck_program(w, eps=0.01, defs=None):
    out = [defs if defs is not None else DEFS, data_lets(), f"let w = {lit(w)}", "print gradient(w, x, y)", "print loss(w, x, y)"]
    for i in range(V):
        for j in range(V):
            for sign, tag in ((1, "p"), (-1, "m")):
                wp = [row[:] for row in w]; wp[i][j] = round(wp[i][j] + sign * eps, 10)
                out.append(f"let w{tag}_{i}_{j} = {lit(wp)}")
    for i in range(V):
        for j in range(V): out.append(f"print loss(wp_{i}_{j}, x, y)\nprint loss(wm_{i}_{j}, x, y)")
    return "\n".join(out) + "\n"

def run_mg(source, mgc=None):
    mgc = mgc or os.path.join(here, "mgc")
    with tempfile.NamedTemporaryFile("w", suffix=".mg", delete=False) as f: f.write(source); path = f.name
    try: r = subprocess.run([mgc, "run", path], capture_output=True, text=True, timeout=600)
    finally: os.unlink(path)
    if r.returncode != 0: raise RuntimeError(f"mgc failed ({r.returncode}): {r.stderr.strip()[:400]}")
    tensors = []
    for chunk in r.stdout.split("Unranked Memref")[1:]:
        data = chunk.split("data =", 1)[1]
        tensors.append([[float(x) for x in re.findall(r"-?(?:nan|inf|\d+(?:\.\d+)?(?:e[-+]?\d+)?)", row)] for row in re.findall(r"\[([^\[\]]+)\]", data)])
    return tensors, r.stdout
def close(a, b, tol=1e-5):
    return len(a) == len(b) and all(len(r) == len(q) and all(abs(x - y) <= tol * max(1.0, abs(y)) for x, y in zip(r, q)) for r, q in zip(a, b))
