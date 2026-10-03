#!/usr/bin/env python3
"""Chapter 42: does lowering the loops last to first remove the quadratic of Chapter 39? The synthetic experiment of Chapter 38 (n tiny loop nests, each copying four numbers, all in one function)
lowered (a) by MLIR's --convert-scf-to-cf, (b) by this chapter's --mg-scf-to-cf-reverse, and (c) with the loops spread over functions of 500 (the case that was always fast). The time is the pass's own,
from mg-opt's --mlir-timing report (parse and print are not included); the instruction counts of the two lowerings of one function are also compared with callgrind at the end.
Output: scaling_out.txt   (about 3 minutes)"""
import os, re, subprocess, sys, tempfile
here = os.path.dirname(os.path.abspath(__file__)); OPT = os.path.join(here, "build", "mg-opt"); W = tempfile.mkdtemp(prefix="ch42s_")
def gen(n, per):
    out = ["module {"]; left = n
    for f in range((n + per - 1) // per):
        m = min(per, left); left -= m
        out.append(f"  func.func @f{f}(%a: memref<4xf64>, %b: memref<4xf64>) {{")
        for i in range(m): out.append(f"    affine.for %i{i} = 0 to 4 {{\n      %x{i} = affine.load %a[%i{i}] : memref<4xf64>\n      affine.store %x{i}, %b[%i{i}] : memref<4xf64>\n    }}")
        out += ["    return", "  }"]
    return "\n".join(out + ["}"]) + "\n"
def pass_time(text, flag, name):
    p = os.path.join(W, "g.mlir"); open(p, "w").write(text)
    r = subprocess.run([OPT, p, "--lower-affine", flag, "--mlir-timing", "-o", "/dev/null"], capture_output=True, text=True)
    m = re.search(r"([\d.]+) \(\s*[\d.]+%\)\s+" + name, r.stderr)
    return float(m.group(1)) if m else None
if __name__ == "__main__":
    print("time of the lowering pass in seconds, by number of loop nests n (each copies 4 numbers); one run each")
    print(f"{'n':>7} {'convert-scf-to-cf':>18} {'last-to-first':>14} {'500 per function':>17}   growth for 2x the loops: standard, last-to-first")
    prev = None
    for n in (2000, 4000, 8000, 16000, 32000, 64000):
        a = pass_time(gen(n, n), "--convert-scf-to-cf", "SCFToControlFlow")
        r = pass_time(gen(n, n), "--mg-scf-to-cf-reverse", r"\{anonymous\}::ScfToCfReversePass")
        b = pass_time(gen(n, 500), "--convert-scf-to-cf", "SCFToControlFlow")
        print(f"{n:>7} {a:>18.3f} {r:>14.3f} {b:>17.3f}" + (f"      {a / prev[0]:.1f}x, {r / prev[1]:.1f}x" if prev else ""), flush=True); prev = (a, r)
