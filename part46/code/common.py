"""Helpers shared by the Chapter 45 scripts: run a Mountain Goat program with the real compiler and read the matrices it prints; evaluate a flattened program in plain Python."""
import math, os, re, subprocess, sys
here = os.path.dirname(os.path.abspath(__file__)); MGC = os.path.join(here, "mgc")
def run_matrices(path, *flags, env=None):
    """Compile and run `path` with mgc; return the printed matrices as lists of rows (nan and inf preserved)."""
    e = dict(os.environ); e.update(env or {}); r = subprocess.run([MGC, "run", path, *flags], capture_output=True, text=True, env=e)
    if r.returncode: raise RuntimeError(f"mgc run {path} failed ({r.returncode}): {r.stderr[:300]}")
    out = []
    for block in r.stdout.split("Unranked Memref")[1:]:
        m = re.search(r"sizes = \[(\d+), (\d+)\].*?data = \s*(.*)", block, re.S); rows, cols = int(m.group(1)), int(m.group(2))
        nums = [float(x) for x in re.findall(r"-?(?:\d+\.?\d*(?:e[+-]?\d+)?|inf|nan)", m.group(3), re.I)]
        out.append([nums[i * cols:(i + 1) * cols] for i in range(rows)])
    return out
def close(a, b, rel=1e-5, absolute=1e-8):
    """Two matrices agree when every element differs by at most `rel` of the larger of the pair (the programs print six significant digits) plus `absolute` times the largest element of either matrix
    (so an exact zero is allowed to meet a finite-difference 1e-10)."""
    if len(a) != len(b) or any(len(x) != len(y) for x, y in zip(a, b)): return False
    scale = max([abs(v) for row in a for v in row] + [abs(v) for row in b for v in row] + [1e-300])
    return all(abs(u - v) <= rel * max(abs(u), abs(v)) + absolute * scale for ra, rb in zip(a, b) for u, v in zip(ra, rb))
