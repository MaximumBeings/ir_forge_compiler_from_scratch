#!/usr/bin/env python3
"""Chapter 43: what do the outlined calls cost at RUN time? Chapter 38 measured compile time and only single, small run times (0.4 s against 0.5 s at 32 steps). Here: each program compiled with the loops
lowered last to first and (a) no outlining, (b) --outline, at clang -O0 and -O2; each executable run REPEATS times pinned to one core; the table gives minimum and median wall time of the run and the
ratio outlined / plain of each. The two executables of a program are checked to print the same thing. Output: bench_runtime_out.txt   (about 15 minutes)"""
import os, re, statistics, subprocess, sys, tempfile, time
here = os.path.dirname(os.path.abspath(__file__)); ROOT = os.path.join(here, "..", ".."); MGC = os.path.join(ROOT, "part42", "code", "mgc"); REPEATS = int(os.environ.get("REPEATS", "7"))
PROGS = [("ch35 10 steps (785 lines)", "part35/code/examples/03_train_10_steps.mg", ("-O0", "-O2")),
         ("ch36 10 steps (1,817 lines)", "part36/code/examples/03_train_10_steps.mg", ("-O0", "-O2")),
         ("ch36 200 steps (29,552 lines)", "part36/code/examples/04_train_200_steps.mg", ("-O0",))]
W = tempfile.mkdtemp(prefix="ch43b_")
def build(prog, opt, outline):
    exe = f"{W}/{os.path.basename(prog)}.{opt}.{'out' if outline else 'plain'}"
    t = time.time(); r = subprocess.run([MGC, "build", os.path.join(ROOT, prog), "-o", exe, opt, "--reverse-loops"] + (["--outline"] if outline else []), capture_output=True, text=True); return exe, time.time() - t, r.returncode
def run(exe):
    times = []; out = None
    for _ in range(REPEATS):
        t = time.time(); r = subprocess.run(["taskset", "-c", "1", exe], capture_output=True, text=True); times.append(time.time() - t); out = re.sub(r"base@ = 0x[0-9a-f]+", "base@ = 0x", r.stdout)
    return min(times), statistics.median(times), out
print(f"run time in seconds, {REPEATS} runs each, pinned to one core; compile time of that executable in brackets")
print(f"{'program':32} {'clang':>5} {'plain min':>10} {'median':>7} {'outlined min':>13} {'median':>7} {'min ratio':>10} {'median ratio':>13}  same output")
for name, prog, opts in PROGS:
    for opt in opts:
        a, ca, ra = build(prog, opt, False); b, cb, rb = build(prog, opt, True)
        if ra or rb: print(f"{name:32} {opt:>5} build failed ({ra}, {rb})"); continue
        pa = run(a); pb = run(b)
        print(f"{name:32} {opt:>5} {pa[0]:>10.3f} {pa[1]:>7.3f} {pb[0]:>13.3f} {pb[1]:>7.3f} {pb[0] / pa[0]:>10.2f} {pb[1] / pa[1]:>13.2f}  {pa[2] == pb[2]}   (compile {ca:.0f} s plain, {cb:.0f} s outlined)", flush=True)
