#!/usr/bin/env python3
"""Checks Mountain Goat's contract(...) against the DEFINITION of a contraction, written here as plain nested loops with no matrix product in sight.

For each case: build two tensors of small whole numbers (or quarters, which are exact in binary), write a .mg program that reshapes each literal and
contracts them, compile and run it with mgc, parse the printed tensor, and compare it with the definition's answer exactly (same numbers, same shape).
Usage: check_contractions.py [path-to-mgc]      Exit status 0 only if every case agrees.
"""
import itertools, os, re, subprocess, sys, tempfile
here = os.path.dirname(os.path.abspath(__file__))
mgc = sys.argv[1] if len(sys.argv) > 1 else os.path.join(here, "mgc")

def product(xs):
    p = 1
    for x in xs: p *= x
    return p

def contract_by_definition(a, sa, b, sb, ia, ib):
    """out[free_a..., free_b...] = sum over the contracted index tuple of a[...] * b[...]. a and b are flat row-major lists."""
    fa = [d for d in range(len(sa)) if d not in ia]; fb = [d for d in range(len(sb)) if d not in ib]
    def strides(s):
        st, acc = [0] * len(s), 1
        for i in range(len(s) - 1, -1, -1): st[i] = acc; acc *= s[i]
        return st
    sta, stb = strides(sa), strides(sb)
    out = []
    for fi in itertools.product(*[range(sa[d]) for d in fa]):
        for fj in itertools.product(*[range(sb[d]) for d in fb]):
            total = 0
            for ci in itertools.product(*[range(sa[d]) for d in ia]):     # the contracted index, in row-major order of the pairs as listed
                offa = sum(i * sta[d] for i, d in zip(fi, fa)) + sum(i * sta[d] for i, d in zip(ci, ia))
                offb = sum(j * stb[d] for j, d in zip(fj, fb)) + sum(i * stb[d] for i, d in zip(ci, ib))
                total += a[offa] * b[offb]
            out.append(total)
    shape = [sa[d] for d in fa] + [sb[d] for d in fb]
    return shape, out

def tensor_text(name, shape, vals):
    return f"let {name} = reshape([[{', '.join(repr(v) if v != int(v) else str(int(v)) for v in vals)}]], {', '.join(map(str, shape))})"

def run_mg(source):
    with tempfile.NamedTemporaryFile("w", suffix=".mg", delete=False) as f: f.write(source); path = f.name
    try: r = subprocess.run([mgc, "run", path], capture_output=True, text=True, timeout=120)
    finally: os.unlink(path)
    if r.returncode != 0: raise RuntimeError(f"mgc failed ({r.returncode}): {r.stderr.strip()}")
    m = re.search(r"sizes = \[([\d, ]*)\].*?data = \s*(.*)", r.stdout, re.S)
    sizes = [int(x) for x in m.group(1).split(",")]
    nums = [float(x) for x in re.findall(r"-?\d+(?:\.\d+)?(?:e[-+]?\d+)?", m.group(2))]
    return sizes, nums

def lcg(seed, n, quarters=False):
    x, out = seed, []
    for _ in range(n):
        x = (x * 1103515245 + 12345) % (2 ** 31)
        v = (x >> 8) % 11 - 5
        out.append(v / 4 if quarters else float(v))
    return out

CASES = [  # name, shape A, axes A, shape B, axes B   (the first nine are Chapter 27's, the rest are new)
    ("matrix product", (3, 2), (1,), (2, 4), (0,)),
    ("double contraction", (2, 3, 4), (1, 2), (3, 4, 5), (0, 1)),
    ("contracted axis in the FRONT of A", (2, 3, 4), (0,), (2, 5), (0,)),
    ("contracted axes in reverse order", (2, 3, 4), (2, 1), (4, 3, 5), (0, 1)),
    ("contracted axes in the middle of both", (5, 2, 3), (1, 2), (4, 3, 2, 6), (2, 1)),
    ("vector times matrix", (4,), (0,), (4, 6), (0,)),
    ("dot product (every axis contracted)", (2, 3, 4), (0, 1, 2), (2, 3, 4), (0, 1, 2)),
    ("outer product (nothing contracted)", (3,), (), (4,), ()),
    ("rank 3 x rank 3, one shared axis", (3, 4, 5), (2,), (5, 2, 3), (0,)),
    ("a 3-cycle of axes on both sides", (2, 3, 4), (1, 0), (3, 2, 5), (0, 1)),
    ("contracted axes scattered, order swapped", (3, 2, 4, 2), (2, 0), (4, 5, 3), (0, 2)),
    ("rank 5 operand", (2, 2, 2, 2, 3), (4, 1), (3, 2, 2), (0, 2)),
    ("size-1 axes", (1, 3, 1), (1,), (3, 1), (0,)),
]

failures = 0
for variant, quarters in (("whole numbers", False), ("quarters", True)):
    print(f"-- {variant}")
    for k, (name, sa, ia, sb, ib) in enumerate(CASES):
        a = lcg(7 + k, product(sa), quarters); b = lcg(100 + k, product(sb), quarters)
        shape, want = contract_by_definition(a, sa, b, sb, ia, ib)
        want_shape = shape if shape else [1, 1]
        src = tensor_text("a", sa, a) + "\n" + tensor_text("b", sb, b) + "\n" + \
              f"print contract(a, ({', '.join(map(str, ia))}), b, ({', '.join(map(str, ib))}))\n"
        try: got_shape, got = run_mg(src)
        except RuntimeError as e: print(f"  FAIL {name}: {e}"); failures += 1; continue
        ok = got_shape == want_shape and got == [float(x) for x in want]
        failures += not ok
        print(f"  {'ok  ' if ok else 'FAIL'} {name:42s} A{list(sa)} B{list(sb)} -> {want_shape}" + ("" if ok else f"\n       got {got_shape} {got[:8]}...\n       want {want_shape} {want[:8]}..."))
print("all cases agree with the definition" if failures == 0 else f"{failures} CASE(S) DISAGREE")
sys.exit(1 if failures else 0)
