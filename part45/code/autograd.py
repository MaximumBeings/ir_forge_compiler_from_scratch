#!/usr/bin/env python3
"""Reverse-mode automatic differentiation for Mountain Goat, as a source-to-source transformation.

  autograd.py prog.mg [--loss N] --wrt NAME[,NAME...]  > grad.mg

reads a Mountain Goat program, takes the N-th `print` (default the first) as the LOSS (it must be a 1x1 matrix), and writes a NEW Mountain Goat program that computes the loss and the
gradient of the loss with respect to each named `let` matrix: the same language, so the result is compiled and run by the ordinary `mgc`, with nothing new in the compiler.

How it works (the whole method is on the page): it asks the real front end for the `mg` dialect text (`mgc mlir`), inlines every function call so the program is one straight-line list of
operations, drops what the loss does not depend on, writes the FORWARD pass out as `let` statements, then walks the operations in REVERSE order. Every operation has a rule that turns the
gradient of its result (the "adjoint") into contributions to the adjoints of its inputs; a value used twice receives the sum of its contributions. The rules are the ones the hand-derived
backward passes of Chapters 33 to 36 use. Supported: add sub mul div neg, scalar operations, matmul, transpose, reshape, exp log sqrt relu, row/col sum and max, broadcast, ge (gradient 0).
Not supported (it says so): rank other than 2, dynamic shapes, permute, contract.
"""
import argparse, ast, math, os, re, subprocess, sys
here = os.path.dirname(os.path.abspath(__file__)); MGC = os.path.join(here, "mgc")

class Unsupported(Exception): pass
def shape_of(t):
    m = re.findall(r"tensor<([\dx?]+)xf64>", t)
    if not m: raise Unsupported("no tensor type in: " + t)
    d = m[-1].split("x")
    if "?" in d: raise Unsupported("dynamic shapes are not supported")
    if len(d) != 2: raise Unsupported(f"rank {len(d)} tensors are not supported")
    return (int(d[0]), int(d[1]))
class Op:
    def __init__(s, res, op, args, attrs, shape): s.res, s.op, s.args, s.attrs, s.shape = res, op, args, attrs, shape
def parse(text):
    funcs = {}; cur = None
    for raw in text.split("\n"):
        line = raw.strip()
        m = re.match(r"func\.func @(\w+)\((.*?)\) -> .*\{$", line)
        if m: cur = dict(params=[(a, shape_of(t)) for a, t in re.findall(r"%(\w+): (tensor<[\dx?]+xf64>)", m.group(2))], ops=[], ret=None); funcs[m.group(1)] = cur; continue
        if cur is None or line in ("}", ""): continue
        m = re.match(r"%(\w+) = mg\.constant dense<(.*)> : (tensor<.*>)$", line)
        if m: cur["ops"].append(Op(m.group(1), "constant", [], {"data": ast.literal_eval(m.group(2))}, shape_of(m.group(3)))); continue
        m = re.match(r"%(\w+) = func\.call @(\w+)\((.*?)\) : .*-> (tensor<.*>)$", line)
        if m: cur["ops"].append(Op(m.group(1), "call", [a.strip()[1:] for a in m.group(3).split(",") if a.strip()], {"callee": m.group(2)}, shape_of(m.group(4)))); continue
        m = re.match(r"mg\.print %(\w+) :", line)
        if m: cur["ops"].append(Op("", "print", [m.group(1)], {}, (0, 0))); continue
        m = re.match(r"func\.return %(\w+) :", line)
        if m: cur["ret"] = m.group(1); continue
        m = re.match(r"%(\w+) = mg\.(\w+) ([^{:]*?)\s*(\{.*\})?\s*: (.*)$", line)
        if m:
            attrs = {k: v.strip().strip('"') for k, v in re.findall(r'(\w+) = ("[^"]*"|[^,}]+?)(?= :|,|\})', m.group(4) or "")}
            cur["ops"].append(Op(m.group(1), m.group(2), [a.strip()[1:] for a in m.group(3).split(",") if a.strip()], attrs, shape_of(m.group(5)))); continue
    return funcs
def flatten(funcs):
    ops = []; counter = [0]
    def inline(fname, argmap, prefix):
        env = dict(argmap)
        for o in funcs[fname]["ops"]:
            if o.op == "call":
                counter[0] += 1; env[o.res] = inline(o.attrs["callee"], {p[0]: env[a] for p, a in zip(funcs[o.attrs["callee"]]["params"], o.args)}, f"{prefix}c{counter[0]}_")
            elif o.op == "print": ops.append(Op("", "print", [env[o.args[0]]], {}, (0, 0)))
            else: name = prefix + o.res; env[o.res] = name; ops.append(Op(name, o.op, [env[a] for a in o.args], dict(o.attrs), o.shape))
        return env.get(funcs[fname]["ret"])
    inline("main", {}, ""); return ops

def lit(data):
    return "[" + ", ".join("[" + ", ".join(repr(float(x)) for x in row) + "]" for row in data) + "]"
def source_lets(path):
    """[(name, literal)] of every `let NAME = [[...]]` in the source, in file order (to give the constants of the IR their names back)."""
    out = []
    for l in open(path):
        m = re.match(r"\s*let\s+(\w+)\s*=\s*(\[\[.*\]\])\s*(#.*)?$", l)
        if m:
            try: out.append((m.group(1), ast.literal_eval(m.group(2))))
            except Exception: pass
    return out
def name_constants(ops, lets):
    """Match the `let` lines to the constants of the flattened program IN ORDER: the front end creates one constant per literal, in the order the source mentions them, so the k-th let is
    the first not-yet-used constant after the previous match that has equal data (this tells apart lets with equal values, like two all-zero bias rows)."""
    consts = [o for o in ops if o.op == "constant"]; pos = 0; found = {}
    norm = lambda d: [[float(x) for x in r] for r in d]
    for name, data in lets:
        for k in range(pos, len(consts)):
            if norm(consts[k].attrs["data"]) == norm(data): found[name] = consts[k].res; pos = k + 1; break
    return found

def grad_program(ops, loss_ssa, wrt, names, steps=0, lr=None):
    """ops: flat forward operations; loss_ssa: the 1x1 value; wrt: list of constant ssa names; names: ssa name -> let name of a constant.
    steps == 0: the program prints the loss and then the gradient of each wrt constant. steps > 0: the program performs `steps` gradient-descent steps (p = p - lr * gradient, all wrt matrices
    at once) and prints the loss before the first step and after each one. Returns the text and the list of printed labels."""
    by = {o.res: o for o in ops if o.res}
    need = set(); stack = [loss_ssa]
    while stack:                                  # keep only what the loss depends on
        n = stack.pop()
        if n in need: continue
        need.add(n); stack += by[n].args
    fwd = [o for o in ops if o.res in need]
    out = []; count = [0]
    def new(prefix="v"): count[0] += 1; return f"{prefix}{count[0]}"
    ones = {}
    def ones_of(shape):
        if shape not in ones: ones[shape] = new("ones"); out.append(f"let {ones[shape]} = {lit([[1.0] * shape[1] for _ in range(shape[0])])}")
        return ones[shape]
    zero = [None]
    def zero11():
        if zero[0] is None: zero[0] = new("zero"); out.append(f"let {zero[0]} = [[0.0]]")
        return zero[0]
    shared = {}                                   # constants that are not differentiated: written once, used by every step
    def forward(params):
        """Write the forward pass; `params` maps each wrt constant to the name of its CURRENT value. Returns ssa name -> variable name."""
        var = {}
        for o in fwd:
            if o.op == "constant":
                if o.res in params: var[o.res] = params[o.res]; continue
                if o.res not in shared: shared[o.res] = names.get(o.res) or new(); out.append(f"let {shared[o.res]} = {lit(o.attrs['data'])}")
                var[o.res] = shared[o.res]; continue
            v = new(); var[o.res] = v; a = [var[x] for x in o.args]
            if o.op in ("add", "sub", "mul", "div"): e = f"({a[0]} {dict(add='+', sub='-', mul='*', div='/')[o.op]} {a[1]})"
            elif o.op == "scalar":
                k = float(o.attrs["value"].split()[0]); sym = dict(add="+", sub="-", mul="*", div="/")[o.attrs["op"]]
                e = f"({k!r} {sym} {a[0]})" if o.attrs["reversed"] == "true" else f"({a[0]} {sym} {k!r})"
            elif o.op == "neg": e = f"(0.0 - {a[0]})"
            elif o.op == "matmul": e = f"({a[0]} @ {a[1]})"
            elif o.op == "transpose": e = f"transpose({a[0]})"
            elif o.op == "reshape": e = f"reshape({a[0]}, {o.shape[0]}, {o.shape[1]})"
            elif o.op in ("exp", "log", "sqrt", "relu"): e = f"{o.op}({a[0]})"
            elif o.op == "ge": e = f"ge({a[0]}, {a[1]})"
            elif o.op == "reduce": e = f"{'row' if int(o.attrs['axis'].split()[0]) == 1 else 'col'}_{o.attrs['kind']}({a[0]})"
            elif o.op == "broadcast": e = f"({a[0]} * {ones_of(o.shape)})"
            else: raise Unsupported(f"operation mg.{o.op} is not supported by autograd")
            out.append(f"let {v} = {e}")
        return var
    def backward(var):
        """Write the backward pass for the forward pass named by `var`; returns ssa name -> variable holding d(loss)/d(that value)."""
        adj = {}
        def add_adj(x, expr):
            if x in adj: v = new("g"); out.append(f"let {v} = ({adj[x]} + {expr})"); adj[x] = v
            else: v = new("g"); out.append(f"let {v} = {expr}"); adj[x] = v
        seed = new("g"); out.append(f"let {seed} = [[1.0]]"); adj[loss_ssa] = seed
        for o in reversed(fwd):
            if o.res not in adj or o.op == "constant": continue
            g = adj[o.res]; a = [var[x] for x in o.args]; r = var[o.res]
            if o.op == "add": add_adj(o.args[0], g); add_adj(o.args[1], g)
            elif o.op == "sub": add_adj(o.args[0], g); add_adj(o.args[1], f"(0.0 - {g})")
            elif o.op == "mul": add_adj(o.args[0], f"({g} * {a[1]})"); add_adj(o.args[1], f"({g} * {a[0]})")
            elif o.op == "div": add_adj(o.args[0], f"({g} / {a[1]})"); add_adj(o.args[1], f"(0.0 - (({g} * {a[0]}) / ({a[1]} * {a[1]})))")
            elif o.op == "neg": add_adj(o.args[0], f"(0.0 - {g})")
            elif o.op == "scalar":
                k = float(o.attrs["value"].split()[0]); sym = o.attrs["op"]; rev = o.attrs["reversed"] == "true"
                if sym == "add": add_adj(o.args[0], g)
                elif sym == "sub": add_adj(o.args[0], f"(0.0 - {g})" if rev else g)
                elif sym == "mul": add_adj(o.args[0], f"({g} * {k!r})")
                elif sym == "div": add_adj(o.args[0], f"(0.0 - (({g} * {k!r}) / ({a[0]} * {a[0]})))" if rev else f"({g} / {k!r})")
            elif o.op == "matmul": add_adj(o.args[0], f"({g} @ transpose({a[1]}))"); add_adj(o.args[1], f"(transpose({a[0]}) @ {g})")
            elif o.op == "transpose": add_adj(o.args[0], f"transpose({g})")
            elif o.op == "reshape": s = by[o.args[0]].shape; add_adj(o.args[0], f"reshape({g}, {s[0]}, {s[1]})")
            elif o.op == "exp": add_adj(o.args[0], f"({g} * {r})")
            elif o.op == "log": add_adj(o.args[0], f"({g} / {a[0]})")
            elif o.op == "sqrt": add_adj(o.args[0], f"({g} / ({r} * 2.0))")
            elif o.op == "relu": add_adj(o.args[0], f"({g} * ge({a[0]}, {zero11()}))")
            elif o.op == "ge": pass                                          # a comparison is flat almost everywhere: no gradient flows through it
            elif o.op == "broadcast":
                s_in, s_out = by[o.args[0]].shape, o.shape
                if s_in == (s_out[0], 1) and s_out[1] != 1: e = f"row_sum({g})"
                elif s_in == (1, s_out[1]) and s_out[0] != 1: e = f"col_sum({g})"
                elif s_in == (1, 1): e = f"col_sum(row_sum({g}))"
                else: e = g
                add_adj(o.args[0], e)
            elif o.op == "reduce":
                axis = int(o.attrs["axis"].split()[0]); s = by[o.args[0]].shape
                if o.attrs["kind"] == "sum": add_adj(o.args[0], f"({ones_of(s)} * {g})")
                else:   # max: the gradient goes to the positions that attain the maximum, split equally between ties (so the total over a row or column is exactly g)
                    mask = new("m"); fn = "row_sum" if axis == 1 else "col_sum"; out.append(f"let {mask} = ge({a[0]}, {r})")
                    add_adj(o.args[0], f"({mask} * ({g} / {fn}({mask})))")
            else: raise Unsupported(f"operation mg.{o.op} has no gradient rule")
        for w in wrt:
            if w not in adj: raise Unsupported("the loss does not depend on " + names.get(w, w))
        return adj
    labels = ["loss"]; params = {}
    if steps == 0:
        out.append("# ---- forward pass: the program's own operations, one `let` each"); var = forward(params)
        out.append("# ---- backward pass: the operations in reverse; each adjoint g is d(loss)/d(the value it belongs to)"); adj = backward(var)
        out.append("# ---- results: the loss, then the gradient of each requested matrix"); out.append(f"print {var[loss_ssa]}")
        for w in wrt: out.append(f"print {adj[w]}"); labels.append("grad " + names.get(w, w))
    else:
        for w in wrt: params[w] = names.get(w) or new(); out.append(f"let {params[w]} = {lit(by[w].attrs['data'])}")
        for s in range(steps + 1):
            out.append(f"# ---- step {s}: forward" + (", backward, update" if s < steps else " only (the loss after the last update)")); var = forward(params)
            out.append(f"print {var[loss_ssa]}"); labels.append(f"loss after {s} steps" if s else "loss before any step")
            if s < steps:
                adj = backward(var); upd = {}
                for w in wrt: v = new("p"); out.append(f"let {v} = ({params[w]} - ({adj[w]} * {lr!r}))"); upd[w] = v
                params = upd
        labels = labels[1:]
    return "\n".join(out) + "\n", labels

def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0]); ap.add_argument("program"); ap.add_argument("--loss", type=int, default=0, help="which print is the loss (0 = the first)")
    ap.add_argument("--wrt", required=True, help="comma-separated names of `let` matrices to differentiate with respect to")
    ap.add_argument("--descend", type=int, default=0, metavar="STEPS", help="instead of printing the gradients, write a program that takes STEPS gradient-descent steps on the --wrt matrices and prints the loss after each")
    ap.add_argument("--lr", type=float, default=0.1, help="learning rate for --descend"); a = ap.parse_args(argv)
    text = subprocess.run([MGC, "mlir", a.program], capture_output=True, text=True)
    if text.returncode: sys.exit(text.stderr)
    try: ops = flatten(parse(text.stdout))
    except Unsupported as e: sys.exit("autograd: " + str(e))
    prints = [o for o in ops if o.op == "print"]
    if a.loss >= len(prints): sys.exit(f"autograd: the program has only {len(prints)} print statement(s)")
    loss = prints[a.loss].args[0]; by = {o.res: o for o in ops if o.res}
    if by[loss].shape != (1, 1): sys.exit(f"autograd: the loss must be a 1x1 matrix, this one is {by[loss].shape[0]}x{by[loss].shape[1]}")
    found = name_constants(ops, source_lets(a.program)); names = {}; wrt = []
    for w in a.wrt.split(","):
        if w not in found: sys.exit(f"autograd: no `let {w} = [[...]]` line of {a.program} matches a constant of the program")
        names[found[w]] = w; wrt.append(found[w])
    try: prog, labels = grad_program(ops, loss, wrt, names, a.descend, a.lr)
    except Unsupported as e: sys.exit("autograd: " + str(e))
    sys.stdout.write(f"# generated by autograd.py from {os.path.basename(a.program)}: prints, in order: " + ", ".join(labels) + "\n" + prog)
if __name__ == "__main__": main()
