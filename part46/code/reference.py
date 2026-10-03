#!/usr/bin/env python3
"""An INDEPENDENT reference for the gradients: evaluate the flattened program in plain Python (its own code for every operation, none of autograd's rules) and differentiate the loss by central
finite differences in double precision (step 1e-6; the error of a central difference is about the square of the step, so the result is good to around 1e-9, far better than the six digits the
compiled programs print). Used by check_autograd.py. Shares only the parser (parse, flatten) with autograd.py."""
import math, os, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import autograd as A
def evaluate(ops, loss, consts):
    """ops: flat list of Op; consts: ssa name -> matrix (list of rows) overriding the constants; returns the value (matrix) of `loss`."""
    v = {}
    for o in ops:
        if o.op == "constant": v[o.res] = consts.get(o.res) or [[float(x) for x in r] for r in o.attrs["data"]]; continue
        if o.op == "print": continue
        a = [v[x] for x in o.args]
        mapc = lambda f, m: [[f(x) for x in r] for r in m]
        zipc = lambda f, m, n: [[f(x, y) for x, y in zip(r, s)] for r, s in zip(m, n)]
        def safe(f):
            def g(x):
                try: return f(x)
                except (ValueError, OverflowError): return math.nan
            return g
        if o.op in ("add", "sub", "mul", "div"):
            f = {"add": lambda x, y: x + y, "sub": lambda x, y: x - y, "mul": lambda x, y: x * y, "div": lambda x, y: x / y}[o.op]; v[o.res] = zipc(f, a[0], a[1])
        elif o.op == "scalar":
            k = float(o.attrs["value"].split()[0]); rev = o.attrs["reversed"] == "true"
            f = {"add": lambda x: x + k, "sub": (lambda x: k - x) if rev else (lambda x: x - k), "mul": lambda x: x * k, "div": (lambda x: k / x) if rev else (lambda x: x / k)}[o.attrs["op"]]; v[o.res] = mapc(f, a[0])
        elif o.op == "neg": v[o.res] = mapc(lambda x: -x, a[0])
        elif o.op == "matmul": v[o.res] = [[sum(x * y for x, y in zip(r, c)) for c in zip(*a[1])] for r in a[0]]
        elif o.op == "transpose": v[o.res] = [list(c) for c in zip(*a[0])]
        elif o.op == "reshape":
            flat = [x for r in a[0] for x in r]; R, C = o.shape; v[o.res] = [flat[i * C:(i + 1) * C] for i in range(R)]
        elif o.op == "exp": v[o.res] = mapc(safe(math.exp), a[0])
        elif o.op == "log": v[o.res] = mapc(safe(math.log), a[0])
        elif o.op == "sqrt": v[o.res] = mapc(safe(math.sqrt), a[0])
        elif o.op == "relu": v[o.res] = mapc(lambda x: x if x > 0 else 0.0, a[0])
        elif o.op == "ge": v[o.res] = zipc(lambda x, y: 1.0 if x >= y else 0.0, a[0], a[1])
        elif o.op == "broadcast":
            R, C = o.shape; m = a[0]; v[o.res] = [[m[i if len(m) > 1 else 0][j if len(m[0]) > 1 else 0] for j in range(C)] for i in range(R)]
        elif o.op == "reduce":
            axis = int(o.attrs["axis"].split()[0]); f = sum if o.attrs["kind"] == "sum" else max; m = a[0]
            v[o.res] = [[f(r)] for r in m] if axis == 1 else [[f(c) for c in zip(*m)]]
        else: raise A.Unsupported(o.op)
    return v[loss]
def finite_difference(program, names, loss_index=0, h=1e-6):
    """Return {name: matrix} of d loss / d element for each let name, by central differences of the plain-Python evaluation."""
    text = subprocess.run([A.MGC, "mlir", program], capture_output=True, text=True).stdout
    ops = A.flatten(A.parse(text)); prints = [o for o in ops if o.op == "print"]; loss = prints[loss_index].args[0]
    found = A.name_constants(ops, A.source_lets(program)); out = {}
    for n in names:
        c = next(o for o in ops if o.res == found[n]); base = [[float(x) for x in r] for r in c.attrs["data"]]; g = []
        for i in range(len(base)):
            row = []
            for j in range(len(base[0])):
                up = [r[:] for r in base]; dn = [r[:] for r in base]; up[i][j] += h; dn[i][j] -= h
                row.append((evaluate(ops, loss, {c.res: up})[0][0] - evaluate(ops, loss, {c.res: dn})[0][0]) / (2 * h))
            g.append(row)
        out[n] = g
    return out
