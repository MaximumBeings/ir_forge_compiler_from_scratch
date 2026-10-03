#!/usr/bin/env python3
"""Chapter 42: a LIMIT of the last-to-first pass. It reorders only the top-level statements of a function; n loops inside the body of ONE outer loop are still lowered in program order by the pattern
driver. Time of the lowering pass for one outer loop whose body holds n tiny loops, convert-scf-to-cf against the reverse pass. Output: nested_limit_out.txt   (about 1 minute)"""
import os, re, subprocess, tempfile
here = os.path.dirname(os.path.abspath(__file__)); OPT = os.path.join(here, "build", "mg-opt"); W = tempfile.mkdtemp(prefix="ch42n_")
def gen(n):
    out = ["module {", "  func.func @f(%a: memref<4xf64>, %b: memref<4xf64>) {", "    affine.for %o = 0 to 2 {"]
    for i in range(n): out.append(f"      affine.for %i{i} = 0 to 4 {{\n        %x{i} = affine.load %a[%i{i}] : memref<4xf64>\n        affine.store %x{i}, %b[%i{i}] : memref<4xf64>\n      }}")
    return "\n".join(out + ["    }", "    return", "  }", "}"]) + "\n"
def t(text, flag, name):
    p = os.path.join(W, "g.mlir"); open(p, "w").write(text)
    r = subprocess.run([OPT, p, "--lower-affine", flag, "--mlir-timing", "-o", "/dev/null"], capture_output=True, text=True)
    m = re.search(r"([\d.]+) \(\s*[\d.]+%\)\s+" + name, r.stderr); return float(m.group(1))
print("time of the lowering pass in seconds: ONE outer loop whose body contains n loops")
print(f"{'n':>7} {'convert-scf-to-cf':>18} {'last-to-first':>14}")
for n in (2000, 4000, 8000, 16000):
    a = t(gen(n), "--convert-scf-to-cf", "SCFToControlFlow"); b = t(gen(n), "--mg-scf-to-cf-reverse", r"\{anonymous\}::ScfToCfReversePass")
    print(f"{n:>7} {a:>18.3f} {b:>14.3f}", flush=True)
