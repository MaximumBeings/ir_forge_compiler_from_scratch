#!/usr/bin/env python3
"""Chapter 43: the 200-step training program at clang -O0, plain against outlined, run ALTERNATELY (plain, outlined, plain, ...) so that drift in the machine's speed affects both the same way, each
run pinned to one core. Prints every time, so that the spread can be seen, and the ratio of the minima and of the medians. The instruction counts of the two (count_instructions_out.txt) are
equal to 0.02%, so any difference here is not about the number of instructions executed. Output: bench_interleaved_out.txt   (about 10 minutes)"""
import os, re, statistics, subprocess, tempfile, time
here = os.path.dirname(os.path.abspath(__file__)); ROOT = os.path.join(here, "..", ".."); MGC = os.path.join(here, "mgc"); N = 9
prog = os.path.join(ROOT, "part36", "code", "examples", "04_train_200_steps.mg"); W = tempfile.mkdtemp(prefix="ch43v_")
for tag, fl in (("plain", ["--no-outline"]), ("outlined", [])): subprocess.run([MGC, "build", prog, "-o", f"{W}/{tag}"] + fl, capture_output=True, check=True, env=dict(os.environ, MG_OPT=os.path.join(ROOT, "part42", "code", "build", "mg-opt")))
t = {"plain": [], "outlined": []}
for i in range(N):
    for tag in ("plain", "outlined"):
        s = time.time(); subprocess.run(["taskset", "-c", "1", f"{W}/{tag}"], capture_output=True); t[tag].append(time.time() - s)
for tag in t: print(f"{tag:9} " + " ".join(f"{x:.3f}" for x in t[tag]) + f"   min {min(t[tag]):.3f}  median {statistics.median(t[tag]):.3f}")
print(f"outlined / plain: minima {min(t['outlined']) / min(t['plain']):.3f}, medians {statistics.median(t['outlined']) / statistics.median(t['plain']):.3f}")
