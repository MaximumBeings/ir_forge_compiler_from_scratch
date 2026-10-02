#!/usr/bin/env python3
"""Everything needed to build, run and check the Chapter 32 programs: the Mountain Goat definitions (generalize.mg.defs.in, with the weight-decay strength
filled in), the train/held-out split, an INDEPENDENT Python trainer and greedy decoder, and functions that write complete .mg programs."""
import math, os, re, subprocess, tempfile
here = os.path.dirname(os.path.abspath(__file__))
DEFS_IN = open(os.environ.get("MG_DEFS_FILE") or os.path.join(here, "generalize.mg.defs.in")).read()   # MG_DEFS_FILE: used by model_mutation.py to test a wrong model
V = 5
TOKENS = [0, 1, 2, 0, 1, 3, 0, 1, 2, 0, 2, 3, 0, 1, 4]
PAIRS = list(zip(TOKENS[:-1], TOKENS[1:])); TRAIN, HELD = PAIRS[:10], PAIRS[10:]
LR = 8.0
CHECKPOINTS = [0, 1, 5, 10, 25, 50, 100, 200, 400]
LAMBDAS = [0, 0.001, 0.01, 0.1]          # strengths that train stably with learning rate 8 (a pure decay step multiplies a weight by 1 - 8*strength)
UNSTABLE = 0.3                           # 8 * 0.3 = 2.4 > 2: each step overshoots (the factor is -1.4) and the weights blow up
def onehot(ps, col): return [[1 if j == p[col] else 0 for j in range(V)] for p in ps]
X, Y, XV, YV = onehot(TRAIN, 0), onehot(TRAIN, 1), onehot(HELD, 0), onehot(HELD, 1)
def defs(lam): return DEFS_IN.replace("@LAMBDA@", repr(lam)).replace("@HALF_LAMBDA@", repr(lam / 2))

# ---- the independent Python trainer ------------------------------------------------------------------------------------------------------
def log_softmax_row(r):
    m = max(r); lse = m + math.log(sum(math.exp(v - m) for v in r)); return [v - lse for v in r]
def loss_ref(w, ps): return -sum(log_softmax_row(w[a])[b] for a, b in ps) / len(ps)
def surprise_ref(w, ps): return [-log_softmax_row(w[a])[b] for a, b in ps]
def gradient_ref(w, ps, lam):
    g = [[0.0] * V for _ in range(V)]
    for a, b in ps:
        p = [math.exp(v) for v in log_softmax_row(w[a])]
        for j in range(V): g[a][j] += (p[j] - (1 if j == b else 0)) / len(ps)
    return [[g[i][j] + lam * w[i][j] for j in range(V)] for i in range(V)]
def train_ref(lam, steps=max(CHECKPOINTS)):
    w = [[0.0] * V for _ in range(V)]; hist = {0: (loss_ref(w, TRAIN), loss_ref(w, HELD))}
    for k in range(1, steps + 1):
        g = gradient_ref(w, TRAIN, lam); w = [[w[i][j] - LR * g[i][j] for j in range(V)] for i in range(V)]
        hist[k] = (loss_ref(w, TRAIN), loss_ref(w, HELD))
    return w, hist
def probabilities_ref(w): return [[math.exp(v) for v in log_softmax_row(r)] for r in w]
def greedy_ref(w, start, n):
    p = probabilities_ref(w); out = [start]
    for _ in range(n): out.append(max(range(V), key=lambda j: p[out[-1]][j]))
    return out
def objective_ref(w, lam): return loss_ref(w, TRAIN) + lam / 2 * sum(v * v for r in w for v in r)

# ---- writing the Mountain Goat programs ---------------------------------------------------------------------------------------------------
def lit(m): return "[" + ", ".join("[" + ", ".join(repr(v) if v != int(v) else str(int(v)) for v in row) + "]" for row in m) + "]"
def data_lets(): return f"let x = {lit(X)}\nlet y = {lit(Y)}\nlet xv = {lit(XV)}\nlet yv = {lit(YV)}\n"
def train_program(lam, d=None, checkpoints=CHECKPOINTS):
    out = [d if d is not None else defs(lam), data_lets(), f"let w0 = {lit([[0] * V for _ in range(V)])}"]
    last = max(checkpoints)
    for k in range(1, last + 1): out.append(f"let w{k} = step(w{k - 1}, x, y)")
    for k in checkpoints: out.append(f"print train_loss(w{k}, x, y)\nprint held_out_loss(w{k}, xv, yv)")
    out += [f"print w{last}", f"print held_out_surprise(w{last}, xv, yv)", f"print probabilities(w{last})"]
    return "\n".join(out) + "\n"
def generate_program(lam, start=0, n=8, d=None):
    out = [d if d is not None else defs(lam), data_lets(), f"let w0 = {lit([[0] * V for _ in range(V)])}"]
    for k in range(1, max(CHECKPOINTS) + 1): out.append(f"let w{k} = step(w{k - 1}, x, y)")
    out.append(f"let p = probabilities(w{max(CHECKPOINTS)})\nlet ids = [[0], [1], [2], [3], [4]]\nlet g0 = {lit([[1 if j == start else 0 for j in range(V)]])}")
    for k in range(1, n + 1): out.append(f"let g{k} = next_token(g{k - 1}, p)")
    out.append("print p")
    for k in range(n + 1): out.append(f"print g{k} @ ids")
    return "\n".join(out) + "\n"
def objective_check_program(w, lam, eps=0.01):
    out = [defs(lam), data_lets(), f"let w = {lit(w)}", "print gradient(w, x, y)", "print objective(w, x, y)"]
    for i in range(V):
        for j in range(V):
            for sign, tag in ((1, "p"), (-1, "m")):
                wp = [row[:] for row in w]; wp[i][j] = round(wp[i][j] + sign * eps, 10)
                out.append(f"let w{tag}_{i}_{j} = {lit(wp)}")
    for i in range(V):
        for j in range(V): out.append(f"print objective(wp_{i}_{j}, x, y)\nprint objective(wm_{i}_{j}, x, y)")
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
