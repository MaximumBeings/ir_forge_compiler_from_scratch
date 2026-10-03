#!/usr/bin/env python3
"""Chapter 38 (follow-up): WHY is SCFToControlFlow super-linear in the loops of one function? A differential profile with valgrind's callgrind. The same synthetic function
(n tiny loop nests, as in synthetic.py) is lowered (--lower-affine --convert-scf-to-cf) at n = 1000, 2000, 4000 and 8000 under `valgrind --tool=callgrind`, which counts
instructions per function. A function whose count grows 4x per doubling of n is quadratic; one that grows 2x is linear. Prints the functions that account for the growth.
Output: profile_scf_out.txt   (about 6 minutes)"""
import os, re, subprocess, sys, tempfile
here = os.path.dirname(os.path.abspath(__file__)); OPT = os.path.join(here, "build", "mg-opt"); W = tempfile.mkdtemp(prefix="ch38cg_")
def gen(n):
    out = ["module {", "  func.func @f(%a: memref<4xf64>, %b: memref<4xf64>) {"]
    for i in range(n): out.append(f"    affine.for %i{i} = 0 to 4 {{\n      %x{i} = affine.load %a[%i{i}] : memref<4xf64>\n      affine.store %x{i}, %b[%i{i}] : memref<4xf64>\n    }}")
    return "\n".join(out + ["    return", "  }", "}"]) + "\n"
def profile(n):
    src = f"{W}/g{n}.mlir"; open(src, "w").write(gen(n)); cg = f"{W}/cg{n}.out"
    subprocess.run(["valgrind", "--tool=callgrind", f"--callgrind-out-file={cg}", OPT, src, "--lower-affine", "--convert-scf-to-cf", "-o", "/dev/null"], capture_output=True, check=True)
    text = subprocess.run(["callgrind_annotate", cg], capture_output=True, text=True).stdout
    funcs = {}; total = 0
    for l in text.split("\n"):
        m = re.match(r"\s*([\d,]+) \(\s*[\d.]+%\)\s+(.*)", l)
        if not m: continue
        ir = int(m.group(1).replace(",", ""))
        if "PROGRAM TOTALS" in m.group(2): total = ir
        else:
            name = re.sub(r"^\?\?\?:", "", m.group(2)); name = re.sub(r" \[.*$", "", name); name = re.sub(r"'\d+$", "", name)
            funcs[name[:150]] = funcs.get(name[:150], 0) + ir
    return total, funcs
sizes = (1000, 2000, 4000, 8000); res = {n: profile(n) for n in sizes}
print("callgrind instruction counts (millions) for --lower-affine --convert-scf-to-cf on n loop nests in one function")
print(f"{'n':>6} {'total':>10} {'growth':>8}")
for k, n in enumerate(sizes): print(f"{n:>6} {res[n][0] / 1e6:>10.1f} {('x%.2f' % (res[n][0] / res[sizes[k - 1]][0])) if k else '':>8}")
a, b = res[2000][1], res[8000][1]
rows = sorted(((b.get(f, 0) - a.get(f, 0), f) for f in b), reverse=True)[:8]
print("\nthe functions that account for the growth from n = 2000 to n = 8000 (instructions in millions at 2000, at 8000, and the ratio; 4x the loops: ratio 4 = linear, 16 = quadratic)")
for d, f in rows: print(f"{a.get(f, 0) / 1e6:>9.1f} {b[f] / 1e6:>10.1f}  x{b[f] / max(a.get(f, 1), 1):>6.1f}  {f}")
