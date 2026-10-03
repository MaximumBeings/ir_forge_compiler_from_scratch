#!/usr/bin/env python3
"""Chapter 39: WHY is SCFToControlFlow super-linear in the number of loops in one function? A differential profile with valgrind's callgrind (it counts instructions, and
with --cache-sim=yes simulated cache misses, per function and per caller). The same synthetic function (n tiny loop nests, as in Chapter 38's synthetic.py) is lowered
(--lower-affine --convert-scf-to-cf) under callgrind at several n. A function whose instruction count grows 4x when n doubles twice... (see the printed header) is quadratic.
Three parts: (1) instruction counts per function, n = 1000..8000: which function grows quadratically? (2) who calls it, and how many cache misses does it cause? (3) the same
program after Chapter 38's --mg-outline-loops: is that function still there?   Output: profile_out.txt   (about 8 minutes)"""
import os, re, subprocess, sys, tempfile
here = os.path.dirname(os.path.abspath(__file__)); OPT = os.environ.get("MG_OPT") or os.path.join(here, "..", "..", "part38", "code", "build", "mg-opt"); W = tempfile.mkdtemp(prefix="ch39_")
def gen(n):
    out = ["module {", "  func.func @f(%a: memref<4xf64>, %b: memref<4xf64>) {"]
    for i in range(n): out.append(f"    affine.for %i{i} = 0 to 4 {{\n      %x{i} = affine.load %a[%i{i}] : memref<4xf64>\n      affine.store %x{i}, %b[%i{i}] : memref<4xf64>\n    }}")
    return "\n".join(out + ["    return", "  }", "}"]) + "\n"
def run(n, extra=(), cache=False):
    src = f"{W}/g{n}.mlir"; open(src, "w").write(gen(n)); cg = f"{W}/cg{n}_{len(extra)}{int(cache)}.out"
    subprocess.run(["valgrind", "--tool=callgrind", *(["--cache-sim=yes"] if cache else []), f"--callgrind-out-file={cg}", OPT, src, *extra, "--lower-affine", "--convert-scf-to-cf", "-o", "/dev/null"], capture_output=True, check=True)
    return cg
def annotate(cg, *flags): return subprocess.run(["callgrind_annotate", *flags, cg], capture_output=True, text=True).stdout
def functions(cg):
    funcs = {}; total = 0
    for l in annotate(cg).split("\n"):
        m = re.match(r"\s*([\d,]+) \(\s*[\d.]+%\)\s+(.*)", l)
        if not m: continue
        ir = int(m.group(1).replace(",", ""))
        if "PROGRAM TOTALS" in m.group(2): total = ir
        else:
            name = re.sub(r"^\?\?\?:", "", m.group(2)); name = re.sub(r" \[.*$", "", name); name = re.sub(r"'\d+$", "", name)[:140]
            funcs[name] = funcs.get(name, 0) + ir
    return total, funcs
SB = "llvm::ilist_traits<mlir::Operation>::transferNodesFromList"
def sb(funcs): return sum(v for k, v in funcs.items() if k.startswith(SB))
print("PART 1. callgrind instruction counts (millions) for --lower-affine --convert-scf-to-cf on n loop nests in ONE function")
sizes = (1000, 2000, 4000, 8000); res = {n: functions(run(n)) for n in sizes}
print(f"{'n':>6} {'all functions':>14} {'growth':>7} {'transferNodesFromList':>22} {'growth':>7}")
for k, n in enumerate(sizes):
    t, f = res[n]; s = sb(f)
    print(f"{n:>6} {t / 1e6:>14.1f} {('x%.2f' % (t / res[sizes[k - 1]][0])) if k else '':>7} {s / 1e6:>22.1f} {('x%.2f' % (s / sb(res[sizes[k - 1]][1]))) if k else '':>7}")
a, b = res[2000][1], res[8000][1]
print("\nthe functions that account for the growth from n = 2000 to n = 8000 (millions of instructions at 2000, at 8000, ratio; 4x the loops: ratio 4 = linear, 16 = quadratic)")
for d, f in sorted(((b.get(f, 0) - a.get(f, 0), f) for f in b), reverse=True)[:6]: print(f"{a.get(f, 0) / 1e6:>9.1f} {b[f] / 1e6:>10.1f}  x{b[f] / max(a.get(f, 1), 1):>5.1f}  {f[:110]}")
print("\nPART 2. who calls it, and the cache misses (callgrind --cache-sim=yes, n = 6000)")
cg = run(6000, cache=True)
lines = annotate(cg, "--tree=caller", "--show=Ir,D1mr,D1mw").split("\n")
callers = [re.sub(r"\s+", " ", l)[:150] for l in lines if re.search(r"<\s*\?\?\?:mlir::Block::splitBlock", l)]
func = [re.sub(r"\s+", " ", l)[:150] for l in lines if re.search(r"\*\s+\?\?\?:llvm::ilist_traits<mlir::Operation>::transferNodesFromList", l)]
print("columns: instructions, L1 read misses, L1 write misses (each with its share of the whole program)")
print("its caller (Block::splitBlock):", callers[0]); print("the function itself:          ", func[0])
tot = annotate(cg, "--show=Ir,D1mr,D1mw")
m = [l for l in tot.split("\n") if "PROGRAM TOTALS" in l][0]; print("program totals:", re.sub(r"\s+", " ", m))
print("\nPART 3. the same function after --mg-outline-loops (Chapter 38): instruction counts at n = 2000 and 8000")
for n in (2000, 8000):
    t, f = functions(run(n, extra=["--mg-outline-loops"])); print(f"n = {n}: all functions {t / 1e6:.1f} million, transferNodesFromList {sb(f) / 1e6:.2f} million, Block::splitBlock present: {any('Block::splitBlock' in k for k in f)}")
