#!/usr/bin/env python3
"""Chapter 44: reordering additions changes the last bits of every sum, and Chapter 35 found that its 200-step training run is chaotic (a change in the last bit grows until the printed numbers
disagree after about step 50). So: the 10-step training programs of Chapters 35 and 36 compiled at clang -O2 plain and with --fast-math, both for the baseline x86-64 and with -march=native (which has fused multiply-add, so `contract`
can change results), run, and their printed outputs compared: how many of the printed numbers differ at six digits, and where the first difference is. (The 200-step programs are NOT used: at -O2
the 200-step Chapter 35 program was still compiling after 29 minutes, and was stopped.) Output: training_sensitivity_out.txt   (about 6 minutes)"""
import os, re, subprocess, sys, tempfile, time
here = os.path.dirname(os.path.abspath(__file__)); root = os.path.join(here, "..", ".."); MGC = os.path.join(here, "mgc"); W = tempfile.mkdtemp(prefix="ch44t_")
def nums(s): return re.findall(r"-?\d+\.\d+(?:e[+-]?\d+)?|-?\d+e[+-]?\d+", re.sub(r"base@ = 0x[0-9a-f]+", "", s))
for name, cflags in [(n, c) for n in ("part35/code/examples/03_train_10_steps.mg", "part36/code/examples/03_train_10_steps.mg") for c in ("", "-march=native")]:
    p = os.path.join(root, name); outs = {}; print(f"== {name.split('/')[0]} 10 steps, clang -O2 {cflags}")
    for tag, fl in (("plain", []), ("fast-math", ["--fast-math"])):
        t = time.time(); exe = f"{W}/{tag}"; subprocess.run([MGC, "build", p, "-o", exe, "-O2"] + fl, check=True, capture_output=True, env=dict(os.environ, MGC_CFLAGS=cflags)); c = time.time() - t
        outs[tag] = subprocess.run([exe], capture_output=True, text=True).stdout; print(f"   {tag:10} compile {c:5.0f} s, {len(nums(outs[tag]))} numbers printed", flush=True)
    a, b = nums(outs["plain"]), nums(outs["fast-math"]); diff = [i for i, (x, y) in enumerate(zip(a, b)) if x != y]
    la, lb = outs["plain"].split("\n"), outs["fast-math"].split("\n"); first = next((i for i, (x, y) in enumerate(zip(la, lb)) if re.sub(r"base@ = 0x[0-9a-f]+", "", x) != re.sub(r"base@ = 0x[0-9a-f]+", "", y)), None)
    print(f"   printed numbers: {len(a)} against {len(b)}; {len(diff)} differ in their printed (six-digit) text" + (f"; first differing line is line {first + 1} of {len(la)}:\n      plain:     {la[first][:110]}\n      fast-math: {lb[first][:110]}" if first is not None else "; the outputs are identical"), flush=True)
