#!/usr/bin/env python3
"""Chapter 45: what the generated backward pass costs against the hand-derived one, for Chapter 33's classifier and Chapter 35's transformer block: the number of `let` statements, the size of the
source, and the instructions the compiled program executes (valgrind --tool=callgrind: exact for one environment; compiled with mgc's defaults, clang -O0). The hand-derived programs also print their
gradients, so the comparison is between two programs that print the same numbers. Output: cost_out.txt   (about 3 minutes)"""
import os, re, subprocess, sys, tempfile
here = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, here); W = tempfile.mkdtemp(prefix="ch45k_")
def instructions(prog):
    exe = os.path.join(W, os.path.basename(prog) + ".exe"); subprocess.run([os.path.join(here, "mgc"), "build", prog, "-o", exe], check=True, capture_output=True)
    cg = exe + ".cg"; subprocess.run(["valgrind", "--tool=callgrind", f"--callgrind-out-file={cg}", exe], capture_output=True)
    return int(re.search(r"summary: (\d+)", open(cg).read()).group(1))
CASES = [("Chapter 33 classifier", "h33_attention.mg", "q0,wk0,wv0,wo0"), ("Chapter 35 transformer block", "h35_transformer_step1.mg", "e0,g10,n10,wq0,wk0,wv0,wo0,g20,n20,w10,c10,w20,c20,gf0,nf0,wu0")]
print(f"{'program':30} {'':14} {'let statements':>15} {'source bytes':>13} {'instructions executed':>22}")
for label, f, wrt in CASES:
    p = os.path.join(here, "examples", f); g = os.path.join(W, "ad_" + f)
    open(g, "w").write(subprocess.run([sys.executable, os.path.join(here, "autograd.py"), p, "--wrt", wrt], capture_output=True, text=True, check=True).stdout)
    for tag, path in (("hand-derived", p), ("generated", g)):
        text = open(path).read(); print(f"{label:30} {tag:14} {len(re.findall(r'^let ', text, re.M)):>15,} {len(text):>13,} {instructions(path):>22,}", flush=True)
