#!/usr/bin/env python3
"""Chapter 44: does --fast-math change what the book's programs print? Every Mountain Goat example of the book (under 400 lines, accepted by the front end) is compiled at clang -O2 three ways:
plain; --fast-math (reassoc,contract: the default of the option); and --fast-math=reassoc,contract,nnan,ninf (the same plus 'no NaNs, no infinities': what -ffast-math adds, and what the
softmax examples of Chapter 29 depend on NOT being assumed). The printed matrices are compared number by number (relative 1e-5 or absolute below 1, because `mgc run` prints six digits; a NaN
must be a NaN and an infinity the same infinity). Output: semantics_out.txt   (about 15 minutes)"""
import glob, math, os, re, subprocess, sys
here = os.path.dirname(os.path.abspath(__file__)); root = os.path.join(here, "..", ".."); MGC = os.path.join(here, "mgc")
def numbers(text): return [float(x) if x.lower() not in ("nan", "-nan") else math.nan for x in re.findall(r"-?(?:\d+\.?\d*(?:e[+-]?\d+)?|inf|nan)", re.sub(r"base@ = 0x[0-9a-f]+", "", text), re.I)]
def same(a, b):
    if len(a) != len(b): return False
    for u, v in zip(a, b):
        if math.isnan(u) or math.isnan(v):
            if not (math.isnan(u) and math.isnan(v)): return False
        elif math.isinf(u) or math.isinf(v):
            if u != v: return False
        elif abs(u - v) > 1e-5 * max(1.0, abs(v)): return False
    return True
progs = [f for f in sorted(glob.glob(root + "/part*/code/examples/*.mg") + glob.glob(root + "/tour/code/*.mg")) if sum(1 for _ in open(f)) < 400]
progs = [f for f in progs if subprocess.run([sys.executable, os.path.join(here, "mgfront.py"), f], capture_output=True).returncode == 0]
modes = {"reassoc,contract": ["--fast-math"], "+nnan,ninf": ["--fast-math=reassoc,contract,nnan,ninf"]}
tally = {m: [0, 0, []] for m in modes}
for f in progs:
    base = subprocess.run([MGC, "run", f, "-O2"], capture_output=True, text=True); b = numbers(base.stdout)
    for m, fl in modes.items():
        r = subprocess.run([MGC, "run", f, "-O2"] + fl, capture_output=True, text=True)
        if same(numbers(r.stdout), b) and r.returncode == base.returncode: tally[m][0] += 1
        else: tally[m][1] += 1; tally[m][2].append(os.path.relpath(f, root))
print(f"{len(progs)} programs, each run at -O2 plain and with each fast-math setting; printed numbers compared")
for m, (s, d, names) in tally.items():
    print(f"  --fast-math {m:18}: {s} print the same, {d} differ" + ("" if not names else ":"))
    for n in names: print("      " + n)
