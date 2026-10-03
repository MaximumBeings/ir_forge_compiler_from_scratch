#!/usr/bin/env python3
"""Chapter 41: what the back end does to one small program. Prints the kernels it makes for Chapter 29's stable softmax with and without fusion, and the first instructions of the fused elementwise kernel."""
import os, subprocess, sys
here = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, here)
import ga_backend as B
from compare_with_cpu import MGC, root
from ga import Machine
M = Machine(); path = os.path.join(root, "part29", "code", "examples", "04_softmax_stable.mg")
text = subprocess.run([MGC, "mlir", path], capture_output=True, text=True).stdout
for label, opts in (("no options", dict(cse_on=False, fuse=False, double_buffer=False)), ("cse + fusion", dict(cse_on=True, fuse=True, double_buffer=False))):
    c = B.compile_text(text, M, **opts); sim, outs = B.run_compiled(c, M)
    print(f"== {label}: {len(c.kernels)} kernels, {sim.cycles} cycles, {len(c.prog)} instructions")
    for k in c.kernels: print(f"   {k['kind']:16s} {str(k['shape']):8s} {' '.join(k['ops'])}")
    if label.startswith("cse"):
        k = [k for k in c.kernels if k["kind"].startswith("elementwise")][0]
        print(f"-- the first fused kernel (broadcast sub exp) is {k['end'] - k['start']} instructions (the 2x3 matrix is one tile):")
        for ins in c.prog[k["start"]:k["end"]]: print("   ", ins)
