#!/usr/bin/env python3
"""Chapter 44 follow-up: the 200-step Chapter 35 training program at clang -O1 (the -O2 compile did not finish in 29 minutes), plain and with --fast-math, with -march=native (which has fused multiply-add, so `contract` can change bits).
Reports compile time of each, runs both, and compares everything they print at the six printed digits. Each compile is given 40 minutes. Output: train200_out.txt"""
import os, re, subprocess, sys, tempfile, time
here = os.path.dirname(os.path.abspath(__file__)); MGC = os.path.join(here, "mgc"); P = os.path.join(here, "..", "..", "part35", "code", "examples", "04_train_200_steps.mg"); W = tempfile.mkdtemp(prefix="c44t_"); res = {}
env = dict(os.environ, MGC_CFLAGS="-march=native")
procs = {}
for tag, fl in (("plain", []), ("fastmath", ["--fast-math"])):
    exe = f"{W}/{tag}"; procs[tag] = (subprocess.Popen([MGC, "build", P, "-o", exe, "-O1"] + fl, env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL), time.time(), exe)
for tag, (p, t0, exe) in procs.items():
    try: p.wait(timeout=2400)
    except subprocess.TimeoutExpired: p.kill(); print(f"{tag}: compile did not finish in 40 minutes (stopped)"); sys.exit(0)
    print(f"{tag}: compiled at -O1 -march=native in {time.time() - t0:.0f} s (both compiles ran at the same time on a 4-core machine)", flush=True)
for tag, (p, t0, exe) in procs.items():
    t = time.time(); r = subprocess.run([exe], capture_output=True, text=True); res[tag] = r.stdout; print(f"{tag}: ran in {time.time() - t:.1f} s, printed {len(re.findall(r'Unranked', r.stdout))} matrices", flush=True)
a, b = res["plain"], res["fastmath"]
na = re.findall(r"-?\d+\.?\d*(?:e[+-]?\d+)?|nan|inf", a); nb = re.findall(r"-?\d+\.?\d*(?:e[+-]?\d+)?|nan|inf", b)
diff = [i for i, (x, y) in enumerate(zip(na, nb)) if x != y]
print(f"printed numbers: {len(na)} vs {len(nb)}; {len(diff)} differ at the printed digits" + (f"; first difference at number #{diff[0]} ({na[diff[0]]} vs {nb[diff[0]]})" if diff else ""))
lossA = [m for m in re.findall(r"\[\[([-0-9.e+]+)\]\]", a)]; lossB = [m for m in re.findall(r"\[\[([-0-9.e+]+)\]\]", b)]
print("1x1 matrices (the printed losses/accuracies), plain then fast-math:"); print("  " + " ".join(lossA)); print("  " + " ".join(lossB))
