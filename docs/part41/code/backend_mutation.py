#!/usr/bin/env python3
"""READ THIS FIRST: this script writes WRONG versions of the back end (ga_backend.py) and of the simulator's extension (ga_ext.py), one mistake each, and runs check_backend.py on each.
A "caught" line is the EXPECTED, wanted result: it shows the checker can notice that mistake, and says which checks noticed. "NOT CAUGHT" would be a gap. Both files are restored
afterwards. Output: backend_mutation_out.txt   (about 10 minutes)"""
import os, subprocess, sys
here = os.path.dirname(os.path.abspath(__file__)); files = {n: os.path.join(here, n) for n in ("ga_backend.py", "ga_ext.py")}; orig = {n: open(p).read() for n, p in files.items()}
print("NOTE: this script deliberately breaks the back end. 'caught' lines are EXPECTED: they show the checker can detect the mistake.")
def check(): return subprocess.run([sys.executable, os.path.join(here, "check_backend.py")], capture_output=True, text=True, cwd=here)
names = {"print the same": "agreement with the CPU on the examples", "rejected": "the rejection reasons", "8 combinations": "the option combinations", "tiles of 4": "other machines", "softmax (stable)": "softmax cycles", "8-token block": "block cycles",
         "fusion turns": "fusion's kernels", "double buffering changes": "double buffering", "1, 2, 4 and 8 tokens": "decode cycles", "proportional": "utilization", "refused": "unsupported programs"}
def kinds(r):
    fails = [l.strip()[5:].strip() for l in r.stdout.split("\n") if l.strip().startswith("FAIL")]; out = []
    for f in fails:
        k = next((v for key, v in names.items() if key in f), "other")
        if k not in out: out.append(k)
    return fails, out
try:
    r = check(); print("baseline (nothing broken):", "checker passes (expected)" if r.returncode == 0 else "UNEXPECTED FAILURE")
    def mut(label, fname, old, new):
        if old not in orig[fname]: print(f"{label}: MUTATION DID NOT APPLY"); return
        open(files[fname], "w").write(orig[fname].replace(old, new, 1)); r = check(); fails, k = kinds(r)
        if r.returncode != 0 and not fails: print(f"{label}: caught (the checker did not finish: {r.stderr.strip().splitlines()[-1][:90]})")
        elif fails: print(f"{label}: caught by {len(fails)} failing check(s) ({', '.join(k)})")
        else: print(f"{label}: NOT CAUGHT")
        open(files[fname], "w").write(orig[fname])
    mut("a broadcast operand is fetched at the output tile's own coordinates (not projected onto its size-1 axis)", "ga_backend.py", "coords = lambda v: (i if self.shapes[v][0] == R else 0, j if self.shapes[v][1] == C else 0)", "coords = lambda v: (i, j)")
    mut("a max-reduction pads a partial tile with 0 instead of -infinity", "ga_backend.py", 'fill = 0.0 if kind == "sum" else float("-inf")', "fill = 0.0")
    mut("common-subexpression elimination ignores the operation's attributes (two scalar ops with different constants look equal)", "ga_backend.py", "key = (o.op, tuple(o.args), tuple(sorted(o.attrs.items())), o.shape)", "key = (o.op, tuple(o.args), o.shape)")
    mut("transpose loads the tile at the output's coordinates (the tiles are not swapped)", "ga_backend.py", '("load", a, src, j, i)', '("load", a, src, i, j)')
    mut("a scalar operation ignores 'reversed' (k - x computed as x - k)", "ga_backend.py", 'o.attrs["reversed"] == "true"', "False")
    mut("matmul is compiled with its operands swapped", "ga_backend.py", "a=a, b=b, c=o.res)", "a=b, b=a, c=o.res)")
    mut("a fused kernel stores only its last value (values used later by other kernels are lost)", "ga_backend.py", "outs = [o.res for o in grp if any(self.ops[u].res not in names for u in uses.get(o.res, [])) or not uses.get(o.res)]", "outs = [o.res for o in grp[-1:]]")
    mut("double buffering uses the same slots for both tiles (the next tile's loads overwrite the current tile)", "ga_backend.py", "parts[t + 1] = steps[t + 1]((t + 1) % 2)", "parts[t + 1] = steps[t + 1](0)")
    mut("the matmul block is the first that fits, not the best by the model", "ga_backend.py", "if best is None or est < best[0] - 1e-9: best = (est, bi, bj, db)", "if best is None: best = (est, bi, bj, db)")
    mut("useful utilization counts the padding", "ga_backend.py", "self.useful_macs += M * K * N", "self.useful_macs += self.tiles(M) * self.tiles(K) * self.tiles(N) * self.m.T ** 3")
    mut("a column vector is broadcast as a row (bcastrow where bcastcol belongs)", "ga_backend.py", 'elif sc == 1 and sr == o.shape[0]: comp.append(("bcastcol", d, s[0]))', 'elif sc == 1 and sr == o.shape[0]: comp.append(("bcastrow", d, s[0]))')
    mut("masklen in the simulator ignores its fill value", "ga_ext.py", "if i < r and j < c else fill for j in range(T)] for i in range(T)]", "if i < r and j < c else 0.0 for j in range(T)] for i in range(T)]")
    mut("the simulator's vscalar swaps its operands when reversed is false", "ga_ext.py", "g(k, x) if rev else g(x, k)", "g(x, k) if rev else g(k, x)")
    mut("exp overflow raises instead of giving infinity", "ga_ext.py", "except OverflowError: return float(\"inf\")", "except OverflowError: raise")
finally:
    for n, p in files.items(): open(p, "w").write(orig[n])
print("\nrestored:", "ga_backend.py and ga_ext.py are back to their originals" if all(open(files[n]).read() == orig[n] for n in files) else "RESTORE FAILED")
