#!/usr/bin/env python3
"""Chapter 45: ten gradient-descent steps (learning rate 3.0) on Chapter 33's attention classifier, using ONLY the gradients autograd.py generates, next to the loss Chapter 33's own hand-derived
trainer printed after 0, 1, 5 and 10 steps. Output: descend_out.txt   (about 20 seconds)"""
import os, subprocess, sys, tempfile
here = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, here); from common import run_matrices
g = os.path.join(tempfile.mkdtemp(prefix="ch45d_"), "descend.mg")
open(g, "w").write(subprocess.run([sys.executable, os.path.join(here, "autograd.py"), os.path.join(here, "examples", "h33_attention.mg"), "--wrt", "q0,wk0,wv0,wo0", "--descend", "10", "--lr", "3.0"], capture_output=True, text=True, check=True).stdout)
mine = [m[0][0] for m in run_matrices(g)]; ch33 = dict(zip((0, 1, 5, 10), [m[0][0] for m in run_matrices(os.path.join(here, "..", "..", "part33", "code", "examples", "03_train.mg"))[:8:2]]))
print(f"{'steps':>5} {'loss with generated gradients':>30} {'Chapter 33 (hand-derived)':>28}")
for s, v in enumerate(mine): print(f"{s:>5} {v:>30.6g} {('%.6g' % ch33[s]) if s in ch33 else '(not printed there)':>28}")
