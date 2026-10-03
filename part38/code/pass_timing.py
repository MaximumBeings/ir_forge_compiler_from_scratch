#!/usr/bin/env python3
"""Chapter 38: which pass is the slow one? Runs mg-opt's own timing report (--mlir-timing) on the lowering of Chapter 36's training program, and then times just
SCFToControlFlow at 1, 2, 4, 8, 16 and 32 steps against the number of loop nests (affine.for) in the program. Output: pass_timing_out.txt   (about 3 minutes)"""
import os, re, subprocess, sys, tempfile, math
here = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(here, "..", "..", "part36", "code"))
import lm2_lib as M
OPT = os.path.join(here, "build", "mg-opt"); FRONT = os.path.join(here, "mgfront.py"); W = tempfile.mkdtemp(prefix="ch38p_")
LOWER = "--lower-affine --convert-scf-to-cf --mg-lower-assert-to-stderr --convert-math-to-llvm --convert-arith-to-llvm --finalize-memref-to-llvm --convert-func-to-llvm --reconcile-unrealized-casts".split()
def affine(k):
    mg = f"{W}/s{k}.mg"; open(mg, "w").write(M.train_program(steps=k, checkpoints=[0, k]))
    open(f"{W}/s{k}.mlir", "w").write(subprocess.run(["python3", FRONT, mg], capture_output=True, text=True).stdout)
    subprocess.run([OPT, f"{W}/s{k}.mlir", "--convert-mg-to-affine", "-o", f"{W}/s{k}.aff.mlir"], check=True)
    return f"{W}/s{k}.aff.mlir"
def report(path, passes):
    return subprocess.run([OPT, path, *passes, "--mlir-timing", "-o", "/dev/null"], capture_output=True, text=True).stderr
p16 = affine(16)
print("mg-opt --mlir-timing on the lowering of the 16-step program (the passes of mgc's third stage):")
print("\n".join(l for l in report(p16, LOWER).split("\n") if re.search(r"Total Execution|Wall Time|SCFToControl|Parser|ConvertAffine|MgAssert|ConvertMath|ArithToLLVM|FinalizeMemRef|ConvertFuncToLLVM|ReconcileUnrealized|Output|Rest|Total$", l)))
print()
print(f"{'steps':>5} {'loop nests':>10} {'SCFToControlFlow (s)':>21}  growth for each doubling of the number of steps")
prev = None
for k in (1, 2, 4, 8, 16, 32):
    p = affine(k); n = sum(1 for l in open(p) if "affine.for" in l)
    m = re.search(r"([\d.]+) \(\s*[\d.]+%\)\s+SCFToControlFlow", report(p, ["--lower-affine", "--convert-scf-to-cf"])); t = float(m.group(1))
    print(f"{k:>5} {n:>10} {t:>21.2f}" + (f"  loops x{n / prev[0]:.2f}, time x{t / prev[1]:.2f}" if prev else ""), flush=True); prev = (n, t)
