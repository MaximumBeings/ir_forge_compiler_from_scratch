#!/usr/bin/env python3
"""Chapter 38: is the cost really about the NUMBER OF LOOPS IN ONE FUNCTION? A synthetic experiment that isolates it: n tiny loop nests (copy four numbers) written as
MLIR, (a) all in one function, (b) in functions of 500 nests each, (c) all in one function but first passed through --mg-outline-loops (min-loops 32). For each, the time of the
lowering pass SCFToControlFlow (from mg-opt's own --mlir-timing report) after --lower-affine; for (c) also the wall-clock time of the whole mg-opt run (parse, outline, lower, print). Output: synthetic_out.txt   (about 2 minutes)"""
import os, re, subprocess, sys, tempfile, time
here = os.path.dirname(os.path.abspath(__file__)); OPT = os.path.join(here, "build", "mg-opt"); W = tempfile.mkdtemp(prefix="ch38s_")
def gen(n, per):
    out = ["module {"]; left = n
    for f in range((n + per - 1) // per):
        m = min(per, left); left -= m
        out.append(f"  func.func @f{f}(%a: memref<4xf64>, %b: memref<4xf64>) {{")
        for i in range(m): out.append(f"    affine.for %i{i} = 0 to 4 {{\n      %x{i} = affine.load %a[%i{i}] : memref<4xf64>\n      affine.store %x{i}, %b[%i{i}] : memref<4xf64>\n    }}")
        out += ["    return", "  }"]
    return "\n".join(out + ["}"]) + "\n"
def scf_time(text, outline=False):
    p = os.path.join(W, "g.mlir"); open(p, "w").write(text)
    cmd = [OPT, p] + (["--mg-outline-loops"] if outline else []) + ["--lower-affine", "--convert-scf-to-cf", "--mlir-timing", "-o", "/dev/null"]
    t = time.time(); r = subprocess.run(cmd, capture_output=True, text=True); wall = time.time() - t; m = re.search(r"([\d.]+) \(\s*[\d.]+%\)\s+SCFToControlFlow", r.stderr)
    return (float(m.group(1)), wall) if m else None
print("SCFToControlFlow time in seconds, by number of loop nests n (each copies 4 numbers); one run each")
print(f"{'n':>7} {'one function':>13} {'500 per function':>17} {'one function, outlined first':>29} {'whole mg-opt run, outlined':>27}")
prev = None
for n in (2000, 4000, 8000, 16000, 32000):
    a = scf_time(gen(n, n))[0]; b = scf_time(gen(n, 500))[0]; c, cw = scf_time(gen(n, n), outline=True)
    print(f"{n:>7} {a:>13.3f} {b:>17.3f} {c:>29.3f} {cw:>27.3f}" + (f"      one function grew {a / prev:.1f}x for 2x the loops" if prev else ""), flush=True); prev = a
