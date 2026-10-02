#!/usr/bin/env python3
"""Checks Mountain Goat's softmax and attention against an independent Python implementation (math.exp, plain lists), and checks properties that
must hold whatever the numbers are. mgc prints six significant digits, so numbers are compared with a relative tolerance of 1e-5.

  * softmax of random score matrices (including scores of +-500, where the naive formula overflows) equals the reference;
  * every row of softmax output sums to 1 and is positive;
  * adding a constant to every score leaves the softmax unchanged (shift invariance);
  * attention (with and without a causal mask) equals the reference; masked weights are EXACTLY 0 and rows still sum to 1.
Usage: check_attention.py [path-to-mgc]      Exit status 0 only if every check passes.
"""
import math, os, re, subprocess, sys, tempfile
here = os.path.dirname(os.path.abspath(__file__))
mgc = sys.argv[1] if len(sys.argv) > 1 else os.path.join(here, "mgc")

def run_mg(source):
    with tempfile.NamedTemporaryFile("w", suffix=".mg", delete=False) as f: f.write(source); path = f.name
    try: r = subprocess.run([mgc, "run", path], capture_output=True, text=True, timeout=120)
    finally: os.unlink(path)
    if r.returncode != 0: raise RuntimeError(f"mgc failed ({r.returncode}): {r.stderr.strip()}")
    tensors = []
    for chunk in r.stdout.split("Unranked Memref")[1:]:
        data = chunk.split("data =", 1)[1]
        tensors.append([[float(x) for x in re.findall(r"-?(?:nan|inf|\d+(?:\.\d+)?(?:e[-+]?\d+)?)", row)] for row in re.findall(r"\[([^\[\]]+)\]", data)])
    return tensors

def lcg(seed):
    x = seed
    while True:
        x = (x * 1103515245 + 12345) % (2 ** 31); yield x / 2 ** 31

def matrix(rng, r, c, lo, hi): return [[round(lo + (hi - lo) * next(rng), 3) for _ in range(c)] for _ in range(r)]
def lit(m): return "[" + ", ".join("[" + ", ".join(repr(v) for v in row) + "]" for row in m) + "]"
def mm(a, b): return [[sum(a[i][k] * b[k][j] for k in range(len(b))) for j in range(len(b[0]))] for i in range(len(a))]
def tr(a): return [list(r) for r in zip(*a)]
def softmax_ref(s):
    out = []
    for row in s:
        m = max(row); e = [math.exp(v - m) for v in row]; t = sum(e); out.append([v / t for v in e])
    return out
def close(a, b, tol=1e-5):
    return len(a) == len(b) and all(len(r) == len(q) and all(abs(x - y) <= tol * max(1.0, abs(y)) for x, y in zip(r, q)) for r, q in zip(a, b))

def softmax_def(r, c): return f"def softmax(x: tensor[{r}x{c}]) = exp(x - row_max(x)) / row_sum(exp(x - row_max(x)))\n"

failures = 0
def report(ok, name, detail=""):
    global failures
    failures += not ok
    print(f"  {'ok  ' if ok else 'FAIL'} {name}" + ("" if ok else f"\n       {detail}"))

print("-- softmax against the reference, rows sum to 1, shift invariance")
rng = lcg(11)
for (r, c, lo, hi) in [(1, 1, -3, 3), (1, 5, -3, 3), (4, 4, -10, 10), (3, 7, -20, 20), (2, 6, 480, 500), (2, 6, -500, -480), (2, 6, -1500, -1000), (5, 3, -500, 500)]:
    s = matrix(rng, r, c, lo, hi)
    shifted = [[v + 37 for v in row] for row in s]
    src = softmax_def(r, c) + f"print softmax({lit(s)})\nprint softmax({lit(shifted)})\n"
    try: got, got_shift = run_mg(src)
    except RuntimeError as e: report(False, f"softmax {r}x{c} scores in [{lo}, {hi}]", str(e)); continue
    want = softmax_ref(s)
    sums_ok = all(abs(sum(row) - 1) < 1e-5 and all(v >= 0 for v in row) for row in got)
    report(close(got, want), f"softmax {r}x{c}, scores in [{lo}, {hi}]: equals the reference", f"got {got[:2]} want {want[:2]}")
    report(sums_ok, f"softmax {r}x{c}, scores in [{lo}, {hi}]: rows are positive and sum to 1", f"row sums {[sum(x) for x in got]}")
    report(close(got_shift, want), f"softmax {r}x{c}, scores in [{lo}, {hi}]: adding 37 to every score changes nothing", f"got {got_shift[:2]} want {want[:2]}")

print("-- attention (n tokens of width d) against the reference, with and without a causal mask")
rng = lcg(5)
for (n, d) in [(1, 1), (2, 3), (3, 2), (4, 4), (5, 3)]:
    q, k, v = matrix(rng, n, d, -2, 2), matrix(rng, n, d, -2, 2), matrix(rng, n, d, -5, 5)
    scale = 1 / math.sqrt(d)
    mask = [[0 if j <= i else -1000000000 for j in range(n)] for i in range(n)]
    src = (softmax_def(n, n) +
           f"def weights(q: tensor[{n}x{d}], k: tensor[{n}x{d}]) = softmax(q @ transpose(k) * {scale!r})\n"
           f"def causal(q: tensor[{n}x{d}], k: tensor[{n}x{d}], mask: tensor[{n}x{n}]) = softmax(q @ transpose(k) * {scale!r} + mask)\n"
           f"let q = {lit(q)}\nlet k = {lit(k)}\nlet v = {lit(v)}\nlet mask = {lit(mask)}\n"
           "print weights(q, k) @ v\nprint causal(q, k, mask)\nprint causal(q, k, mask) @ v\n")
    try: out, wc, outc = run_mg(src)
    except RuntimeError as e: report(False, f"attention n={n} d={d}", str(e)); continue
    sc = [[x * scale for x in row] for row in mm(q, tr(k))]
    want_out = mm(softmax_ref(sc), v)
    scm = [[sc[i][j] + mask[i][j] for j in range(n)] for i in range(n)]
    want_w = softmax_ref(scm); want_outc = mm(want_w, v)
    report(close(out, want_out), f"attention n={n} d={d}: output equals the reference", f"got {out[:2]} want {want_out[:2]}")
    report(close(wc, want_w) and close(outc, want_outc), f"causal attention n={n} d={d}: weights and output equal the reference", f"got {wc[:2]} want {want_w[:2]}")
    zero_ok = all(wc[i][j] == 0.0 for i in range(n) for j in range(i + 1, n)) and all(abs(sum(row) - 1) < 1e-5 for row in wc)
    report(zero_ok, f"causal attention n={n} d={d}: weights above the diagonal are exactly 0, rows sum to 1", f"weights {wc}")
print("all checks pass" if failures == 0 else f"{failures} CHECK(S) FAILED")
sys.exit(1 if failures else 0)
