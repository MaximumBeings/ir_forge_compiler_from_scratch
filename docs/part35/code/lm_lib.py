#!/usr/bin/env python3
"""Everything needed to build, run and check the Chapter 35 programs: the Mountain Goat definitions of a one-block, one-head, causal transformer language model
and of its hand-derived backward pass, written for B sequences stacked into one matrix, and functions that write the complete .mg programs. The independent
Python implementation they are checked against is lm_ref.py."""
import math, os, re, subprocess, sys, tempfile
import lm_ref as R
here = os.path.dirname(os.path.abspath(__file__))
MGC = os.path.join(here, "..", "..", "part32", "code", "mgc")        # this chapter adds no compiler operation: it uses Chapter 32's compiler
V, N, D, H = R.V, R.N, R.D, R.H
B = 16; BN = B * N; NT = B * len(R.TARGETS)          # 16 sequences stacked: 112 rows; 64 predictions per batch
LR, STEPS = 1.0, 200
CHECKPOINTS = [0, 1, 10, 25, 50, 100, 150, 200]
SC = repr(R.SC)
NAMES = {"emb": "e", "g1": "g1", "bt1": "n1", "wq": "wq", "wk": "wk", "wv": "wv", "wo": "wo", "g2": "g2", "bt2": "n2", "w1": "w1", "b1": "c1", "w2": "w2", "b2": "c2", "gf": "gf", "bf": "nf", "wout": "wu"}
ORDER = R.ORDER
SHAPE = {"emb": (V, D), "g1": (1, D), "bt1": (1, D), "wq": (D, D), "wk": (D, D), "wv": (D, D), "wo": (D, D), "g2": (1, D), "bt2": (1, D), "w1": (D, H), "b1": (1, H), "w2": (H, D), "b2": (1, D), "gf": (1, D), "bf": (1, D), "wout": (D, V)}
def ty(r, c): return f"tensor[{r}x{c}]"
CONST = [("x", ty(BN, V)), ("ps", ty(BN, D)), ("mk", ty(BN, BN))]            # tokens (one-hot), positions, and the attention mask
TARGET = [("y", ty(BN, V)), ("mr", ty(BN, 1))]                                 # the next tokens (zero rows where there is no target) and which rows are targets
PARAMS = [(NAMES[k], ty(*SHAPE[k])) for k in ORDER]

def lit(m): return "[" + ", ".join("[" + ", ".join(repr(v) if v != int(v) else str(int(v)) for v in row) + "]" for row in m) + "]"
def onehot(rows, width=V): return [[1 if j == t else 0 for j in range(width)] for t in rows]
def x_rows(data): return onehot([t for s in data for t in s])
def y_rows(data): return [[1 if (i in R.TARGETS and j == s[i + 1]) else 0 for j in range(V)] for s in data for i in range(N)]
def mr_rows(): return [[1 if i in R.TARGETS else 0] for _ in range(B) for i in range(N)]
def ps_rows(): return [R.POS[i] for _ in range(B) for i in range(N)]
def mask_rows(): return [[0 if (r // N == c // N and c % N <= r % N) else -1000000000 for c in range(BN)] for r in range(BN)]       # block diagonal (own sequence) and causal (not the future)
def sig(items): return ", ".join(f"{n}: {t}" for n, t in items)
def defs():
    h = f"tensor[{BN}x{D}]"; g = ty(1, D)
    L = [f"def softmax_rows(m: {ty(BN, BN)}) = exp(m - row_max(m)) / row_sum(exp(m - row_max(m)))",
         f"def ln_sigma(h: {h}) = sqrt(row_mean((h - row_mean(h)) * (h - row_mean(h))) + {R.EPS!r})",
         f"def ln_hat(h: {h}) = (h - row_mean(h)) / ln_sigma(h)",
         f"def ln_out(h: {h}, g: {g}, t: {g}) = ln_hat(h) * g + t",
         f"def ln_back(d: {h}, h: {h}, g: {g}) = ((d * g) - row_mean(d * g) - ln_hat(h) * row_mean((d * g) * ln_hat(h))) / ln_sigma(h)",
         f"def log_softmax(z: {ty(BN, V)}) = z - row_max(z) - log(row_sum(exp(z - row_max(z))))"]
    return "\n".join(L) + "\n"
def comments(): return ("# A one-block, one-head, causal transformer language model and its hand-derived backward pass. B = 16 sequences of 7 tokens are stacked into one\n"
                        "# matrix of 112 rows; attention is over all 112 rows with a mask that allows a position to see only earlier positions of its OWN sequence.\n")
def forward_lines(tag, xv, P):
    """The forward pass, one 'let' per step. P maps a parameter name (as in lm_ref) to the variable that holds its current value. Returns the lines and the name of the logits."""
    n = lambda s: f"{s}_{tag}"
    return [f"let {n('x0')} = {xv} @ {P['emb']} + ps",
            f"let {n('u1')} = ln_out({n('x0')}, {P['g1']}, {P['bt1']})",
            f"let {n('q')} = {n('u1')} @ {P['wq']}", f"let {n('k')} = {n('u1')} @ {P['wk']}", f"let {n('v')} = {n('u1')} @ {P['wv']}",
            f"let {n('a')} = softmax_rows({n('q')} @ transpose({n('k')}) * {SC} + mk)",
            f"let {n('o')} = {n('a')} @ {n('v')}",
            f"let {n('x1')} = {n('x0')} + {n('o')} @ {P['wo']}",
            f"let {n('u2')} = ln_out({n('x1')}, {P['g2']}, {P['bt2']})",
            f"let {n('pre')} = {n('u2')} @ {P['w1']} + {P['b1']}",
            f"let {n('r')} = relu({n('pre')})",
            f"let {n('x2')} = {n('x1')} + ({n('r')} @ {P['w2']} + {P['b2']})",
            f"let {n('uf')} = ln_out({n('x2')}, {P['gf']}, {P['bf']})",
            f"let {n('lg')} = {n('uf')} @ {P['wout']}"], n("lg")
def loss_expr(lg, yv): return f"col_sum(row_sum({yv} * log_softmax({lg}))) * -{1 / NT!r}"
def correct_expr(lg, yv): return f"col_sum(row_sum(ge({lg}, row_max({lg})) * {yv}))"
def backward_lines(tag, xv, yv, P):
    """The hand-derived backward pass, one 'let' per step, working backwards from the loss. Returns the lines and a map from parameter name to its gradient variable."""
    n = lambda s: f"{s}_{tag}"; G = lambda k: f"G{NAMES[k]}_{tag}"
    L = [f"let {n('dl')} = (exp(log_softmax({n('lg')})) * mr - {yv}) * {1 / NT!r}",
         f"let {G('wout')} = transpose({n('uf')}) @ {n('dl')}",
         f"let {n('duf')} = {n('dl')} @ transpose({P['wout']})",
         f"let {G('bf')} = col_sum({n('duf')})", f"let {G('gf')} = col_sum({n('duf')} * ln_hat({n('x2')}))",
         f"let {n('dx2')} = ln_back({n('duf')}, {n('x2')}, {P['gf']})",
         f"let {G('b2')} = col_sum({n('dx2')})", f"let {G('w2')} = transpose({n('r')}) @ {n('dx2')}",
         f"let {n('dpre')} = ({n('dx2')} @ transpose({P['w2']})) * ge({n('pre')}, [[0]])",
         f"let {G('b1')} = col_sum({n('dpre')})", f"let {G('w1')} = transpose({n('u2')}) @ {n('dpre')}",
         f"let {n('du2')} = {n('dpre')} @ transpose({P['w1']})",
         f"let {G('bt2')} = col_sum({n('du2')})", f"let {G('g2')} = col_sum({n('du2')} * ln_hat({n('x1')}))",
         f"let {n('dx1')} = {n('dx2')} + ln_back({n('du2')}, {n('x1')}, {P['g2']})",
         f"let {G('wo')} = transpose({n('o')}) @ {n('dx1')}",
         f"let {n('do')} = {n('dx1')} @ transpose({P['wo']})",
         f"let {n('dv')} = transpose({n('a')}) @ {n('do')}", f"let {n('da')} = {n('do')} @ transpose({n('v')})",
         f"let {n('ds')} = {n('a')} * ({n('da')} - row_sum({n('a')} * {n('da')}))",
         f"let {n('dq')} = {n('ds')} @ {n('k')} * {SC}", f"let {n('dk')} = transpose({n('ds')}) @ {n('q')} * {SC}",
         f"let {G('wq')} = transpose({n('u1')}) @ {n('dq')}", f"let {G('wk')} = transpose({n('u1')}) @ {n('dk')}", f"let {G('wv')} = transpose({n('u1')}) @ {n('dv')}",
         f"let {n('du1')} = {n('dq')} @ transpose({P['wq']}) + {n('dk')} @ transpose({P['wk']}) + {n('dv')} @ transpose({P['wv']})",
         f"let {G('bt1')} = col_sum({n('du1')})", f"let {G('g1')} = col_sum({n('du1')} * ln_hat({n('x0')}))",
         f"let {n('dx0')} = {n('dx1')} + ln_back({n('du1')}, {n('x0')}, {P['g1']})",
         f"let {G('emb')} = transpose({xv}) @ {n('dx0')}"]
    return L, {k: G(k) for k in ORDER}
def const_lets(data, name="x", yname="y"):
    return f"let {name} = {lit(x_rows(data))}\nlet {yname} = {lit(y_rows(data))}\n"
def common_lets():
    return f"let ps = {lit(ps_rows())}\nlet mk = {lit(mask_rows())}\nlet mr = {lit(mr_rows())}\n"
def apply_mutant(text):
    old, new = os.environ.get("MG_MUTANT_OLD"), os.environ.get("MG_MUTANT_NEW")          # used by model_mutation.py to test a deliberately wrong backward pass
    return text.replace(old, new) if old else text
def var(k, t): return f"{NAMES[k]}{t}"
def train_program(seed=1, steps=STEPS, checkpoints=CHECKPOINTS, lr=LR):
    p = R.init_params(seed)
    out = [comments(), defs(), common_lets(), const_lets(R.TRAIN, "x", "y"), const_lets(R.TEST, "xt", "yt")]
    out += [const_lets(c, f"xc{i}", f"yc{i}") for i, c in enumerate(R.CHUNKS)] + ["\n".join(f"let {var(k, 0)} = {lit(p[k])}" for k in ORDER)]
    for t in range(1, steps + 1):
        P = {k: var(k, t - 1) for k in ORDER}
        f, lg = forward_lines(f"s{t}", "x", P); b, G = backward_lines(f"s{t}", "x", "y", P)
        out += [f"# ---- step {t}: forward pass, backward pass, update"] + f + b + [f"let {var(k, t)} = {var(k, t - 1)} - {G[k]} * {lr}" for k in ORDER]
    def evaluate(tag, xv, yv, t):
        P = {k: var(k, t) for k in ORDER}; f, lg = forward_lines(tag, xv, P); return f + [f"print {loss_expr(lg, yv)}", f"print {correct_expr(lg, yv)}"]
    for t in checkpoints: out += evaluate(f"c{t}", "x", "y", t)
    out += evaluate("test", "xt", "yt", steps)
    for i in range(len(R.CHUNKS)):
        P = {k: var(k, steps) for k in ORDER}; f, lg = forward_lines(f"ch{i}", f"xc{i}", P); out += f + [f"print {correct_expr(lg, f'yc{i}')}"]
    sel = [[1 if c == r else 0 for c in range(BN)] for r in range(N)]
    out += [f"let selr = {lit(sel)}", f"let selc = {lit([list(r) for r in zip(*sel)])}", f"print selr @ a_c{steps} @ selc"]       # the attention pattern of the first training sequence
    return apply_mutant("\n".join(out) + "\n")
def gradient_program(p, entries, eps=0.001):
    out = [comments(), defs(), common_lets(), const_lets(R.TRAIN, "x", "y"), "\n".join(f"let {var(k, 0)} = {lit(p[k])}" for k in ORDER)]
    P = {k: var(k, 0) for k in ORDER}; f, lg = forward_lines("g", "x", P); b, G = backward_lines("g", "x", "y", P)
    out += f + b + [f"print {G[k]}" for k in ORDER] + [f"print {loss_expr(lg, 'y')}"]
    for key, i, j in entries:
        ls = {}
        for sign, tag in ((1, "p"), (-1, "m")):
            rows = [r[:] for r in p[key]]; rows[i][j] = round(rows[i][j] + sign * eps, 10)
            P2 = dict(P); P2[key] = f"{NAMES[key]}_{tag}"
            f2, lg2 = forward_lines(f"fd{tag}_{key}_{i}_{j}", "x", P2)
            out += [f"let {NAMES[key]}_{tag} = {lit(rows)}"] + f2; ls[tag] = loss_expr(lg2, 'y')
        out.append(f"print ({ls['p']} - {ls['m']}) * {0.5 / eps!r}")       # the DIFFERENCE is formed inside the program, so mgc's six printed digits are spent on it, not on the loss
    return apply_mutant("\n".join(out) + "\n")
def run_mg(source, mgc=None):
    mgc = mgc or MGC
    with tempfile.NamedTemporaryFile("w", suffix=".mg", delete=False) as f: f.write(source); path = f.name
    try: r = subprocess.run([mgc, "run", path], capture_output=True, text=True, timeout=7200)
    finally: os.unlink(path)
    if r.returncode != 0: raise RuntimeError(f"mgc failed ({r.returncode}): {r.stderr.strip()[:600]}")
    tensors = []
    for chunk in r.stdout.split("Unranked Memref")[1:]:
        data = chunk.split("data =", 1)[1]
        tensors.append([[float(x) for x in re.findall(r"-?(?:nan|inf|\d+(?:\.\d+)?(?:e[-+]?\d+)?)", row)] for row in re.findall(r"\[([^\[\]]+)\]", data)])
    return tensors, r.stdout
def close(a, b, tol=1e-5):
    return len(a) == len(b) and all(len(r) == len(q) and all(abs(x - y) <= tol * max(1.0, abs(y)) for x, y in zip(r, q)) for r, q in zip(a, b))
