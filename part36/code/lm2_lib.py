#!/usr/bin/env python3
"""Everything needed to build, run and check the Chapter 36 programs: Chapter 30's architecture (two blocks, two attention heads in each, feed-forward networks, pre-norm
residual connections, a final layer norm) as a causal language model, with its hand-derived backward pass, written for 16 sequences stacked into one matrix.
Shared helpers (the data as matrices, the mask, the loss, running mgc) come from Chapter 35's lm_lib.py. The independent Python implementation these programs are checked
against is lm2_ref.py."""
import os, sys
here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, here); sys.path.insert(0, os.path.join(here, "..", "..", "part35", "code"))
import lm_lib as L1
import lm2_ref as R
from lm_lib import lit, x_rows, y_rows, mr_rows, ps_rows, mask_rows, const_lets, common_lets, loss_expr, correct_expr, run_mg, close, defs, ty, BN, NT, B
V, N, D, DH, H, NB, SC = R.V, R.N, R.D, R.DH, R.H, R.NB, repr(R.SC)
LR, STEPS = 0.5, 200
CHECKPOINTS = [0, 1, 10, 25, 50, 100, 150, 200]
ORDER = R.ORDER
BASE = {"bt1": "n1", "bt2": "n2", "b1": "c1", "b2": "c2"}          # a parameter called t1 would collide with the compiler's own temporaries %t1
def name(k):
    if k == "emb": return "e"
    if k == "bf": return "nf"
    if k == "wout": return "wu"
    if k in ("gf",): return k
    base, b = k.rsplit("_", 1); return f"{BASE.get(base, base)}_{b}"
def split(k): base, b = k.rsplit("_", 1); return base, int(b)
SHAPE = {"emb": (V, D), "gf": (1, D), "bf": (1, D), "wout": (D, V)}
for b in range(1, NB + 1):
    for k, s in {"g1": (1, D), "bt1": (1, D), "g2": (1, D), "bt2": (1, D), "w1": (D, H), "b1": (1, H), "w2": (H, D), "b2": (1, D)}.items(): SHAPE[f"{k}_{b}"] = s
    for h in (1, 2): SHAPE.update({f"wq{h}_{b}": (D, DH), f"wk{h}_{b}": (D, DH), f"wv{h}_{b}": (D, DH), f"wo{h}_{b}": (DH, D)})
def var(k, t): return f"{name(k)}_v{t}"
def comments(): return ("# Chapter 30's architecture as a causal language model, with its hand-derived backward pass: two blocks, each with TWO attention heads of width 4 and a feed-forward\n"
                        "# network of width 16, pre-norm residual connections, a final layer norm. 16 sequences of 7 tokens are stacked into one matrix of 112 rows; attention is over all 112\n"
                        "# rows with a mask that allows a position to see only earlier positions of its OWN sequence.\n")
def forward_lines(tag, xv, P):
    """The forward pass, one 'let' per step. P maps a parameter key (as in lm2_ref) to the variable holding its current value. Returns the lines and the name of the logits."""
    L = []; X = f"x0_{tag}"; L.append(f"let {X} = {xv} @ {P['emb']} + ps")
    for b in range(1, NB + 1):
        n = lambda s: f"{s}_b{b}_{tag}"; p = lambda k: P[f"{k}_{b}"]
        L.append(f"let {n('u1')} = ln_out({X}, {p('g1')}, {p('bt1')})")
        for h in (1, 2):
            L += [f"let {n(f'q{h}')} = {n('u1')} @ {p(f'wq{h}')}", f"let {n(f'k{h}')} = {n('u1')} @ {p(f'wk{h}')}", f"let {n(f'v{h}')} = {n('u1')} @ {p(f'wv{h}')}",
                  f"let {n(f'a{h}')} = softmax_rows({n(f'q{h}')} @ transpose({n(f'k{h}')}) * {SC} + mk)", f"let {n(f'o{h}')} = {n(f'a{h}')} @ {n(f'v{h}')}"]
        L += [f"let {n('x1')} = {X} + {n('o1')} @ {p('wo1')} + {n('o2')} @ {p('wo2')}",
              f"let {n('u2')} = ln_out({n('x1')}, {p('g2')}, {p('bt2')})", f"let {n('pre')} = {n('u2')} @ {p('w1')} + {p('b1')}", f"let {n('r')} = relu({n('pre')})",
              f"let {n('x2')} = {n('x1')} + ({n('r')} @ {p('w2')} + {p('b2')})"]
        X = n("x2")
    L += [f"let uf_{tag} = ln_out({X}, {P['gf']}, {P['bf']})", f"let lg_{tag} = uf_{tag} @ {P['wout']}"]
    return L, f"lg_{tag}"
def backward_lines(tag, xv, yv, P):
    """The hand-derived backward pass, one 'let' per step, working backwards from the loss through the final layer norm, the two blocks (last first) and the embedding."""
    G = lambda k: f"G{name(k)}_{tag}"
    L = [f"let dl_{tag} = (exp(log_softmax(lg_{tag})) * mr - {yv}) * {1 / NT!r}", f"let {G('wout')} = transpose(uf_{tag}) @ dl_{tag}", f"let duf_{tag} = dl_{tag} @ transpose({P['wout']})",
         f"let {G('bf')} = col_sum(duf_{tag})", f"let {G('gf')} = col_sum(duf_{tag} * ln_hat(x2_b{NB}_{tag}))", f"let dX{NB}_{tag} = ln_back(duf_{tag}, x2_b{NB}_{tag}, {P['gf']})"]
    for b in range(NB, 0, -1):
        n = lambda s: f"{s}_b{b}_{tag}"; p = lambda k: P[f"{k}_{b}"]; g = lambda k: G(f"{k}_{b}"); X = f"x0_{tag}" if b == 1 else f"x2_b{b - 1}_{tag}"; dx2 = f"dX{b}_{tag}"
        L += [f"let {g('b2')} = col_sum({dx2})", f"let {g('w2')} = transpose({n('r')}) @ {dx2}",
              f"let {n('dpre')} = ({dx2} @ transpose({p('w2')})) * ge({n('pre')}, [[0]])", f"let {g('b1')} = col_sum({n('dpre')})", f"let {g('w1')} = transpose({n('u2')}) @ {n('dpre')}",
              f"let {n('du2')} = {n('dpre')} @ transpose({p('w1')})", f"let {g('bt2')} = col_sum({n('du2')})", f"let {g('g2')} = col_sum({n('du2')} * ln_hat({n('x1')}))",
              f"let {n('dx1')} = {dx2} + ln_back({n('du2')}, {n('x1')}, {p('g2')})"]
        for h in (1, 2):
            L += [f"let {g(f'wo{h}')} = transpose({n(f'o{h}')}) @ {n('dx1')}", f"let {n(f'do{h}')} = {n('dx1')} @ transpose({p(f'wo{h}')})",
                  f"let {n(f'dv{h}')} = transpose({n(f'a{h}')}) @ {n(f'do{h}')}", f"let {n(f'da{h}')} = {n(f'do{h}')} @ transpose({n(f'v{h}')})",
                  f"let {n(f'ds{h}')} = {n(f'a{h}')} * ({n(f'da{h}')} - row_sum({n(f'a{h}')} * {n(f'da{h}')}))",
                  f"let {n(f'dq{h}')} = {n(f'ds{h}')} @ {n(f'k{h}')} * {SC}", f"let {n(f'dk{h}')} = transpose({n(f'ds{h}')}) @ {n(f'q{h}')} * {SC}",
                  f"let {g(f'wq{h}')} = transpose({n('u1')}) @ {n(f'dq{h}')}", f"let {g(f'wk{h}')} = transpose({n('u1')}) @ {n(f'dk{h}')}", f"let {g(f'wv{h}')} = transpose({n('u1')}) @ {n(f'dv{h}')}"]
        terms = " + ".join(f"{n(f'dq{h}')} @ transpose({p(f'wq{h}')}) + {n(f'dk{h}')} @ transpose({p(f'wk{h}')}) + {n(f'dv{h}')} @ transpose({p(f'wv{h}')})" for h in (1, 2))
        L += [f"let {n('du1')} = {terms}", f"let {g('bt1')} = col_sum({n('du1')})", f"let {g('g1')} = col_sum({n('du1')} * ln_hat({X}))",
              f"let dX{b - 1}_{tag} = {n('dx1')} + ln_back({n('du1')}, {X}, {p('g1')})"]
    L.append(f"let {G('emb')} = transpose({xv}) @ dX0_{tag}")
    return L, {k: G(k) for k in ORDER}
def apply_mutant(text):
    old, new = os.environ.get("MG_MUTANT_OLD"), os.environ.get("MG_MUTANT_NEW")          # used by model_mutation.py to test a deliberately wrong program
    return text.replace(old, new) if old else text
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
    last = checkpoints[-1]
    out += [f"let selr = {lit(sel)}", f"let selc = {lit([list(r) for r in zip(*sel)])}"]
    out += [f"print selr @ a{h}_b{b}_c{last} @ selc" for b in range(1, NB + 1) for h in (1, 2)]       # the four attention patterns of the first training sequence
    return apply_mutant("\n".join(out) + "\n")
def gradient_program(p, entries, eps=0.001):
    out = [comments(), defs(), common_lets(), const_lets(R.TRAIN, "x", "y"), "\n".join(f"let {var(k, 0)} = {lit(p[k])}" for k in ORDER)]
    P = {k: var(k, 0) for k in ORDER}; f, lg = forward_lines("g", "x", P); b, G = backward_lines("g", "x", "y", P)
    out += f + b + [f"print {G[k]}" for k in ORDER] + [f"print {loss_expr(lg, 'y')}"]
    for key, i, j in entries:
        ls = {}
        for sign, tag in ((1, "p"), (-1, "m")):
            rows = [r[:] for r in p[key]]; rows[i][j] = round(rows[i][j] + sign * eps, 10)
            P2 = dict(P); P2[key] = f"{name(key)}_{tag}"
            f2, lg2 = forward_lines(f"fd{tag}_{key}_{i}_{j}", "x", P2)
            out += [f"let {name(key)}_{tag} = {lit(rows)}"] + f2; ls[tag] = loss_expr(lg2, "y")
        out.append(f"print ({ls['p']} - {ls['m']}) * {0.5 / eps!r}")       # the DIFFERENCE is formed inside the program, so mgc's six printed digits are spent on it
    return apply_mutant("\n".join(out) + "\n")
