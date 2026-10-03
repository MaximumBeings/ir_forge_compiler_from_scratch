#!/usr/bin/env python3
"""Chapter 41: does the accelerator back end compute what the CPU path computes? Every Mountain Goat example of Chapters 20 to 32 and the tour is compiled twice: by `mgc run`
(mg-opt, LLVM, native code: the book's real compiler) and by the GA-1 back end, run on the simulator. The printed matrices are compared (mgc prints six significant digits, so
the comparison is relative 1e-5; nan equals nan, inf equals inf). Programs the back end cannot compile say why. Output: compare_out.txt   Usage: compare_with_cpu.py [files...]"""
import glob, math, os, re, subprocess, sys
here = os.path.dirname(os.path.abspath(__file__)); root = os.path.join(here, "..", "..")
sys.path.insert(0, here)
import ga_backend as B
from ga import Machine
MGC = os.path.join(root, "part38", "code", "mgc")
os.environ.setdefault("MG_OPT", os.path.join(root, "part38", "code", "build", "mg-opt"))
def cpu_matrices(path):
    r = subprocess.run([MGC, "run", path], capture_output=True, text=True)
    if r.returncode: return None
    out = []
    for chunk in r.stdout.split("Unranked Memref")[1:]:
        data = chunk.split("data =", 1)[1]
        out.append([[float(x) for x in re.findall(r"-?(?:nan|inf|\d+(?:\.\d+)?(?:e[-+]?\d+)?)", row)] for row in re.findall(r"\[([^\[\]]+)\]", data)])
    return out
def close_matrix(a, b):
    if len(a) != len(b) or any(len(x) != len(y) for x, y in zip(a, b)): return False
    for x, y in zip(a, b):
        for u, v in zip(x, y):
            if math.isnan(u) or math.isnan(v):
                if not (math.isnan(u) and math.isnan(v)): return False
            elif math.isinf(u) or math.isinf(v):
                if u != v: return False
            elif abs(u - v) > 1e-5 * max(1.0, abs(v)): return False
    return True
def close(outs, cpu): return len(outs) == len(cpu) and all(close_matrix(a, b) for a, b in zip(outs, cpu))
def main(files, machine=None, **opts):
    machine = machine or Machine(slots=32); rows = []
    for f in files:
        name = os.path.relpath(f, root)
        text = subprocess.run([MGC, "mlir", f], capture_output=True, text=True)
        if text.returncode: rows.append((name, "front end error", "")); continue
        try: c = B.compile_text(text.stdout, machine, **opts)
        except B.Unsupported as e: rows.append((name, "unsupported", str(e)[:70])); continue
        cpu = cpu_matrices(f)
        if cpu is None: rows.append((name, "cpu run failed", "")); continue
        sim, outs = B.run_compiled(c, machine)
        if not outs: rows.append((name, "prints nothing", "")); continue
        rows.append((name, "same" if close(outs, cpu) else "DIFFERENT", f"{sim.cycles} cycles, useful MXU {sim.useful_utilization:.0%}"))
    return rows
if __name__ == "__main__":
    # every example of Chapters 20 to 32 and the tour; the training programs of Chapters 33 to 36 (thousands of loop nests, matrices of 112 rows) are left out: they would take the
    # pure-Python simulator hours, and Chapter 41 runs the forward pass of a transformer at a smaller size instead
    files = sys.argv[1:] or sorted(f for f in glob.glob(os.path.join(root, "part2[0-9]", "code", "examples", "*.mg")) + glob.glob(os.path.join(root, "part3[0-2]", "code", "examples", "*.mg")) + glob.glob(os.path.join(root, "tour", "code", "*.mg")) if sum(1 for _ in open(f)) < 400)
    rows = main(files)
    for r in rows: print(f"{r[0]:<62} {r[1]:<16} {r[2]}")
    from collections import Counter; c = Counter(r[1] for r in rows); print("\n" + ", ".join(f"{k}: {v}" for k, v in sorted(c.items())))
