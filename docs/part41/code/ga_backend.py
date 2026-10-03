#!/usr/bin/env python3
"""A back end that compiles Mountain Goat to GA-1 (Chapter 40's model accelerator). It reads the `mg` dialect text that the real front end writes (`mgc mlir prog.mg`: the same
IR that mg-opt lowers to LLVM), flattens the calls, and emits a GA-1 program with the data layout and schedule decisions made here:

  * every tensor lives in DRAM (a name -> rows of numbers); every kernel loads the tiles it needs into the scratchpad and stores its results;
  * matmul: Chapter 40's output-stationary blocked schedule, with the block shape and double buffering CHOSEN by comparing the analytic model of Chapter 40 over every shape that fits;
  * elementwise operations (add sub mul div ge neg relu exp sqrt log, scalar operations and broadcasts) are emitted tile by tile; with fusion on, a run of them becomes ONE kernel
    that keeps its intermediate tiles in the scratchpad and stores only what later code needs;
  * reductions (row or column, sum or max) accumulate tile by tile, hiding the padding of a partial tile behind a mask;  transpose is a vector-unit transpose of each tile;
  * options: cse (merge identical pure operations: the front end emits some twice), fuse, double_buffer (software-pipeline the loads of elementwise, reduction and transpose kernels).

Not a MLIR pass: a Python program over the text of the IR. Unsupported (it says so): dynamic shapes, rank other than 2, reshape, permute, contract."""
import math, os, re, sys
from dataclasses import dataclass, field
here = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(here, "..", "..", "part40", "code")); sys.path.insert(0, here)
from ga import Machine
from ga_ext import Sim2
import schedules as S

class Unsupported(Exception): pass

# ------------------------------------------------------------------ parsing the mg dialect text
def shape_of(text):
    m = re.findall(r"tensor<([\dx?]+)xf64>", text)
    if not m: raise Unsupported("no tensor type in: " + text)
    dims = m[-1].split("x")
    if "?" in dims: raise Unsupported("dynamic shapes are not supported by the GA-1 back end")
    if len(dims) != 2: raise Unsupported(f"rank {len(dims)} tensors are not supported by the GA-1 back end")
    return (int(dims[0]), int(dims[1]))

@dataclass
class Op:
    res: str; op: str; args: list; attrs: dict; shape: tuple

def parse(text):
    funcs = {}; cur = None
    for raw in text.split("\n"):
        line = raw.strip()
        m = re.match(r"func\.func @(\w+)\((.*?)\) -> .*\{$", line)
        if m:
            cur = dict(params=[(a, shape_of(t)) for a, t in re.findall(r"%(\w+): (tensor<[\dx?]+xf64>)", m.group(2))], ops=[], prints=[], ret=None); funcs[m.group(1)] = cur; continue
        if cur is None or line in ("}", ""): continue
        m = re.match(r"%(\w+) = mg\.constant dense<(.*)> : (tensor<.*>)$", line)
        if m:
            data = eval(m.group(2).replace("e", "e")); cur["ops"].append(Op(m.group(1), "constant", [], {"data": data}, shape_of(m.group(3)))); continue
        m = re.match(r"%(\w+) = func\.call @(\w+)\((.*?)\) : .*-> (tensor<.*>)$", line)
        if m: cur["ops"].append(Op(m.group(1), "call", [a.strip()[1:] for a in m.group(3).split(",") if a.strip()], {"callee": m.group(2)}, shape_of(m.group(4)))); continue
        m = re.match(r"mg\.print %(\w+) :", line)
        if m: cur["ops"].append(Op("", "print", [m.group(1)], {}, (0, 0))); continue
        m = re.match(r"func\.return %(\w+) :", line)
        if m and cur is not None: cur["ret"] = m.group(1); continue
        m = re.match(r"%(\w+) = mg\.(\w+) ([^{:]*?)\s*(\{.*\})?\s*: (.*)$", line)
        if m:
            attrs = {}
            for k, v in re.findall(r'(\w+) = ("[^"]*"|[^,}]+?)(?= :|,|\})', m.group(4) or ""): attrs[k] = v.strip().strip('"')
            cur["ops"].append(Op(m.group(1), m.group(2), [a.strip()[1:] for a in m.group(3).split(",") if a.strip()], attrs, shape_of(m.group(5)))); continue
    return funcs

def flatten(funcs, entry="main"):
    """Inline every call: one flat list of ops with globally unique names, the constants, and the printed values (in order)."""
    ops = []; counter = [0]
    def inline(fname, argmap, prefix):
        env = dict(argmap)
        for o in funcs[fname]["ops"]:
            if o.op == "call":
                counter[0] += 1; sub = f"{prefix}c{counter[0]}_"
                ret = inline(o.attrs["callee"], {p[0]: env[a] for p, a in zip(funcs[o.attrs["callee"]]["params"], o.args)}, sub); env[o.res] = ret
            elif o.op == "print": ops.append(Op("", "print", [env[o.args[0]]], {}, (0, 0)))
            else:
                name = prefix + o.res; env[o.res] = name; ops.append(Op(name, o.op, [env[a] for a in o.args], dict(o.attrs), o.shape))
        return env.get(funcs[fname]["ret"])
    inline(entry, {}, "")
    return ops

# ------------------------------------------------------------------ middle: cse, dead code, fusion groups
PURE_EW = {"add", "sub", "mul", "div", "ge", "neg", "relu", "exp", "sqrt", "log", "scalar", "broadcast"}
def cse(ops):
    seen = {}; alias = {}; out = []
    for o in ops:
        o.args = [alias.get(a, a) for a in o.args]
        if o.op in ("constant", "print"): out.append(o); continue
        key = (o.op, tuple(o.args), tuple(sorted(o.attrs.items())), o.shape)
        if key in seen: alias[o.res] = seen[key]
        else: seen[key] = o.res; out.append(o)
    return out
def dce(ops):
    live = {a for o in ops if o.op == "print" for a in o.args}; keep = []
    for o in reversed(ops):
        if o.op == "print" or o.res in live: keep.append(o); live.update(o.args)
    return list(reversed(keep))

# ------------------------------------------------------------------ code generation
class Compiler:
    def __init__(self, machine, cse_on=True, fuse=True, double_buffer=True, matmul_block=None):
        self.m = machine; self.cse_on, self.fuse, self.db, self.matmul_block = cse_on, fuse, double_buffer, matmul_block
        self.prog = []; self.dram = {}; self.kernels = []; self.shapes = {}; self.useful_macs = 0     # useful_macs: the multiply-adds the PROGRAM asks for (padding excluded)
    def tiles(self, n): return math.ceil(n / self.m.T)
    # ---- entry point
    def compile(self, ops):
        if self.cse_on: ops = cse(ops)
        ops = dce(ops); self.ops = ops
        for o in ops:
            if o.op == "constant": self.dram[o.res] = [[float(x) for x in row] for row in o.attrs["data"]]; self.shapes[o.res] = o.shape
            elif o.op != "print": self.shapes[o.res] = o.shape
        uses = {}
        for k, o in enumerate(ops):
            for a in o.args: uses.setdefault(a, []).append(k)
        groups = []; cur = []
        def flush():
            nonlocal cur
            if cur: groups.append(("ew", cur)); cur = []
        for k, o in enumerate(ops):
            if o.op == "constant": continue
            if o.op in PURE_EW and self.fuse:
                inside = {c.res for c in cur}
                if cur and (o.shape != cur[-1].shape or (o.op == "broadcast" and o.args[0] in inside)): flush()
                cur.append(o)
            elif o.op in PURE_EW: flush(); groups.append(("ew", [o]))
            elif o.op == "print": flush()
            else: flush(); groups.append((o.op, [o]))
        flush()
        position = {o.res: k for k, o in enumerate(ops)}
        for kind, grp in groups:
            start = len(self.prog); first_op = grp[0]
            if kind == "ew": self.emit_group(grp, uses, position)
            elif kind == "matmul": self.emit_matmul(grp[0])
            elif kind == "reduce": self.emit_reduce(grp[0])
            elif kind == "transpose": self.emit_transpose(grp[0])
            else: raise Unsupported(f"operation mg.{kind} is not supported by the GA-1 back end")
            self.kernels.append(dict(kind=kind if kind != "ew" else "elementwise x%d" % len(grp), shape=grp[-1].shape, start=start, end=len(self.prog), ops=[g.op for g in grp]))
        self.prints = [o.args[0] for o in ops if o.op == "print"]
        return self
    def alloc(self, name, shape): self.dram[name] = [[0.0] * shape[1] for _ in range(shape[0])]
    # ---- matmul
    def choose_block(self, M, K, N):
        if self.matmul_block: return self.matmul_block
        Mt, Nt = self.tiles(M), self.tiles(N); best = None
        for bi in range(1, min(Mt, 8) + 1):
            for bj in range(1, min(Nt, 16) + 1):
                for db in ((True, False) if self.db else (False,)):
                    if bi * bj + (2 if db else 1) * (bi + bj) > self.m.slots: continue
                    est = S.predicted_double_buffered_cycles(M, K, N, self.m, bi, bj) if db else S.predicted_double_buffered_cycles(M, K, N, self.m, bi, bj) * 1.3
                    if best is None or est < best[0] - 1e-9: best = (est, bi, bj, db)
        if best is None: raise Unsupported("scratchpad too small for any matmul block")
        return best[1:]
    def emit_matmul(self, o):
        a, b = o.args; (M, K), (K2, N) = self.shapes[a], self.shapes[b]; bi, bj, db = self.choose_block(M, K, N); self.alloc(o.res, o.shape); self.useful_macs += M * K * N
        self.prog += S.blocked(M, K, N, self.m, bi, bj, db, a=a, b=b, c=o.res); self.last_block = (bi, bj, db)
        o.attrs["block"] = f"{bi}x{bj}{', double buffered' if db else ''}"
    # ---- software pipelining helper for per-tile loops: items = list of (loads, compute, stores) instruction lists using pool p
    def pipeline(self, steps):
        """steps: one function per tile, pool index -> (loads, compute, stores). Without double buffering: loads, compute, stores of each tile in turn. With it, the loads of tile
        t + 1 are emitted BEFORE the compute of tile t, into the other pool of slots, so the DMA queue can run ahead of the vector unit."""
        n = len(steps)
        if not n: return
        if not self.db:
            for f in steps: l, c, st = f(0); self.prog += l + c + st
            return
        parts = [None] * n; parts[0] = steps[0](0); self.prog += parts[0][0]
        for t in range(n):
            if t + 1 < n: parts[t + 1] = steps[t + 1]((t + 1) % 2); self.prog += parts[t + 1][0]
            self.prog += parts[t][1] + parts[t][2]
    # ---- elementwise group
    def emit_group(self, grp, uses, position):
        R, C = grp[-1].shape; Mt, Nt = self.tiles(R), self.tiles(C); names = {o.res for o in grp}; last = position[grp[-1].res]
        ext = []
        for o in grp:
            for a in o.args:
                if a not in names and a not in ext: ext.append(a)
        outs = [o.res for o in grp if any(self.ops[u].res not in names for u in uses.get(o.res, [])) or not uses.get(o.res)]
        for r in outs: self.alloc(r, self.shapes[r])
        # ---- liveness and slot assignment, once per group (relative slot numbers)
        lastuse = {}
        for k, o in enumerate(grp):
            for a in o.args: lastuse[a] = k
        for r in outs: lastuse[r] = len(grp)
        free = []; nxt = [0]; slot = {}
        def take():
            if free: return free.pop()
            nxt[0] += 1; return nxt[0] - 1
        for a in ext: slot[a] = take()
        body = []                                              # (kind, ...) with relative slots
        for k, o in enumerate(grp):
            srcs = [slot[a] for a in o.args]
            d = take(); slot[o.res] = d; body.append((o, srcs, d))
            for a in set(o.args):
                if lastuse.get(a) == k and a not in outs: free.append(slot[a])
            if lastuse.get(o.res, -1) <= k and o.res not in outs: free.append(d)
        K = nxt[0]
        if self.db and 2 * K > self.m.slots: raise Unsupported("scratchpad too small to double buffer an elementwise kernel")
        if K > self.m.slots: raise Unsupported("scratchpad too small for an elementwise kernel")
        def step(i, j):
            def f(pool):
                base = pool * K
                coords = lambda v: (i if self.shapes[v][0] == R else 0, j if self.shapes[v][1] == C else 0)      # a size-1 axis is broadcast: its only tile is tile 0
                loads = [("load", base + slot[a], a, *coords(a)) for a in ext]; comp = []
                for o, srcs, d in body:
                    s = [base + x for x in srcs]; d = base + d; kind = o.op
                    if kind in ("add", "sub", "mul", "div"): comp.append(("vop", kind, d, s[0], s[1]))
                    elif kind == "ge": comp.append(("vop2", "ge", d, s[0], s[1]))
                    elif kind in ("neg", "relu"): comp.append(("vop", kind, d, s[0], None))
                    elif kind in ("exp", "sqrt", "log"): comp.append((kind, d, s[0]))
                    elif kind == "scalar": comp.append(("vscalar", o.attrs["op"], d, s[0], float(o.attrs["value"].split()[0]), o.attrs["reversed"] == "true"))
                    elif kind == "broadcast":
                        sr, sc = self.shapes[o.args[0]]
                        if (sr, sc) == o.shape: comp.append(("vscalar", "mul", d, s[0], 1.0, False))
                        elif sc == 1 and sr == o.shape[0]: comp.append(("bcastcol", d, s[0]))
                        elif sr == 1 and sc == o.shape[1]: comp.append(("bcastrow", d, s[0]))
                        elif (sr, sc) == (1, 1): comp.append(("bcastall", d, s[0]))
                        else: raise Unsupported(f"broadcast {self.shapes[o.args[0]]} -> {o.shape}")
                    else: raise Unsupported(kind)
                stores = [("store", base + slot[r], r, i, j) for r in outs]
                return loads, comp, stores
            return f
        self.pipeline([step(i, j) for i in range(Mt) for j in range(Nt)])
    # ---- reductions
    def emit_reduce(self, o):
        (R, C) = self.shapes[o.args[0]]; axis = int(o.attrs["axis"].split()[0]); kind = o.attrs["kind"]; src = o.args[0]; self.alloc(o.res, o.shape)
        fill = 0.0 if kind == "sum" else float("-inf"); T = self.m.T; Mt, Nt = self.tiles(R), self.tiles(C)
        outer, inner = (Mt, Nt) if axis == 1 else (Nt, Mt)
        if (4 if self.db else 3) * 2 > self.m.slots: raise Unsupported("scratchpad too small")
        for x in range(outer):
            def steps():
                out = []
                for y in range(inner):
                    ti, tj = (x, y) if axis == 1 else (y, x)
                    def f(pool, ti=ti, tj=tj, y=y):
                        base = 2 + pool * 2; t, r = base, base + 1; loads = [("load", t, src, ti, tj)]; comp = []
                        vr, vc = min(T, R - ti * T), min(T, C - tj * T)
                        if vr < T or vc < T: comp.append(("masklen", t, vr, vc, fill))
                        comp.append(("rowred" if axis == 1 else "colred", kind, r, t))
                        comp.append(("vop", "add" if kind == "sum" else "max", 0, 0, r) if y else ("vscalar", "mul", 0, r, 1.0, False))
                        return loads, comp, []
                    out.append(f)
                return out
            st = steps(); self.pipeline(st)
            self.prog.append(("store", 0, o.res, x if axis == 1 else 0, 0 if axis == 1 else x))
    def emit_transpose(self, o):
        src = o.args[0]; R, C = o.shape; Mt, Nt = self.tiles(R), self.tiles(C); self.alloc(o.res, o.shape)
        steps = []
        for i in range(Mt):
            for j in range(Nt):
                def f(pool, i=i, j=j):
                    a, b = pool * 2, pool * 2 + 1
                    return [("load", a, src, j, i)], [("trans", b, a)], [("store", b, o.res, i, j)]
                steps.append(f)
        self.pipeline(steps)

# ------------------------------------------------------------------ running
def compile_text(text, machine, **options):
    return Compiler(machine, **options).compile(flatten(parse(text)))
def run_compiled(c, machine):
    sim = Sim2(machine, c.dram).run(c.prog); sim.useful_utilization = c.useful_macs / (machine.peak_macs_per_cycle * max(sim.cycles, 1)); return sim, [c.dram[p] for p in c.prints]

def kernel_table(c, sim):
    """Per kernel: its instructions, the cycles each engine was busy for it, and the span from its first start to its last finish (kernels overlap through the queues)."""
    rows = []
    for k in c.kernels:
        t = [x for x in sim.trace if k["start"] <= x[0] < k["end"]]
        if not t: continue
        busy = {e: sum(x[3] - x[2] for x in t if x[1] == e) for e in ("dma", "mxu", "vpu")}
        rows.append(dict(kind=k["kind"], shape=k["shape"], instructions=len(t), dma=busy["dma"], mxu=busy["mxu"], vpu=busy["vpu"], span=max(x[3] for x in t) - min(x[2] for x in t)))
    return rows
