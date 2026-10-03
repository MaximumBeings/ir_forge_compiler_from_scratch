#!/usr/bin/env python3
"""Chapter 38: how does the compile time of a big Mountain Goat program grow, stage by stage, and what does --outline change? Takes Chapter 36's training program at 1, 2, 4,
8, 16 and 32 steps (the more steps, the more loop nests in `main`), runs mgc's stages one at a time with a clock on each, with and without the outlining pass, and prints
the times, the number of loop nests (affine.for) and, with outlining, how many distinct functions the nests became. Python: the stage commands are copied from mgc.
Output: scaling_out.txt   (about 4 minutes)"""
import os, subprocess, sys, tempfile, time
here = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(here, "..", "..", "part36", "code"))
import lm2_lib as M
OPT = os.path.join(here, "build", "mg-opt"); FRONT = os.path.join(here, "mgfront.py")
LOWER = "--lower-affine --convert-scf-to-cf --mg-lower-assert-to-stderr --convert-math-to-llvm --convert-arith-to-llvm --finalize-memref-to-llvm --convert-func-to-llvm --reconcile-unrealized-casts".split()
W = tempfile.mkdtemp(prefix="ch38_")
def run(cmd, out=None):
    t = time.time(); r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode: raise RuntimeError(" ".join(cmd) + "\n" + r.stderr[-400:])
    if out: open(out, "w").write(r.stdout)
    return time.time() - t, r
def pipeline(k, outline):
    tag = f"{k}{'o' if outline else ''}"; mg = f"{W}/s{tag}.mg"; open(mg, "w").write(M.train_program(steps=k, checkpoints=[0, k]))
    a, _ = run(["python3", FRONT, mg], f"{W}/s{tag}.mlir")
    b, _ = run([OPT, f"{W}/s{tag}.mlir", "--convert-mg-to-affine", *(["--mg-outline-loops"] if outline else []), "-o", f"{W}/s{tag}.aff.mlir"])
    nests = sum(1 for l in open(f"{W}/s{tag}.aff.mlir") if "affine.for" in l); funcs = sum(1 for l in open(f"{W}/s{tag}.aff.mlir") if "func.func private @mg_outlined" in l)
    c, _ = run([OPT, f"{W}/s{tag}.aff.mlir", *LOWER, "-o", f"{W}/s{tag}.llvm.mlir"])
    d, _ = run(["mlir-translate-18", "--mlir-to-llvmir", f"{W}/s{tag}.llvm.mlir", "-o", f"{W}/s{tag}.ll"])
    e, _ = run(["clang-18", f"{W}/s{tag}.ll", "-o", f"{W}/s{tag}.exe", "-L/usr/lib/llvm-18/lib", "-lmlir_runner_utils", "-lm", "-Wl,-rpath,/usr/lib/llvm-18/lib"])
    f, r = run([f"{W}/s{tag}.exe"])
    return (a, b, c, d, e, f), nests, funcs, r.stdout
print("Chapter 36's training program (examples/04 of that chapter) cut to k steps; times in seconds, one run each, this machine")
print(f"{'steps':>5} {'':>8} {'loop nests':>10} {'outlined fns':>12}  {'front':>6} {'convert':>7} {'lower':>7} {'translate':>9} {'clang':>6} {'run':>5}  {'compile total':>13}")
import re
for k in (1, 2, 4, 8, 16, 32):
    outs = {}
    for outline in (False, True):
        t, nests, funcs, out = pipeline(k, outline); outs[outline] = re.sub(r"base@ = 0x[0-9a-f]+", "", out)
        print(f"{k:>5} {'outlined' if outline else 'plain':>8} {nests:>10} {funcs:>12}  " + " ".join(f"{x:>{w}.1f}" for x, w in zip(t, (6, 7, 7, 9, 6, 5))) + f"  {sum(t[:5]):>13.1f}", flush=True)
    print(f"{'':>5} the program prints the same {len(outs[False].split())} words with and without outlining: {outs[False] == outs[True]}")
