#!/usr/bin/env python3
"""Combine the two benchmark passes into one table: median time in each pass, the spread between passes, and speedup versus
the plain mgc -O2 build of the same size. Usage: summarize.py bench_out_1.txt bench_out_2.txt > summary.txt"""
import re, sys
rx = re.compile(r"^(?P<label>.+?)\s+N=(?P<n>\d+)\s+min\s+(?P<min>[\d.]+) ms\s+median\s+(?P<med>[\d.]+) ms\s+(?P<gf>[\d.]+) GFLOP/s.*?(?P<ok>result ok|RESULT WRONG)")
def load(path):
    d = {}
    for line in open(path):
        m = rx.match(line)
        if m: d[(m["label"].strip(), int(m["n"]))] = (float(m["med"]), float(m["gf"]), m["ok"] == "result ok")
    return d
a, b = load(sys.argv[1]), load(sys.argv[2])
base = {n: (a[("mg_O2 (dynamic sizes)", n)][0] + b[("mg_O2 (dynamic sizes)", n)][0]) / 2 for n in (64, 128, 256, 512)}
print(f"{'implementation':34} {'N':>4} {'pass 1 ms':>10} {'pass 2 ms':>10} {'differ':>7} {'GFLOP/s':>8} {'vs mg -O2':>9}  results")
for n in (64, 128, 256, 512):
    for key in [k for k in a if k[1] == n]:
        (m1, g1, ok1), (m2, g2, ok2) = a[key], b[key]
        mean = (m1 + m2) / 2
        print(f"{key[0]:34} {n:>4} {m1:>10.3f} {m2:>10.3f} {abs(m1 - m2) / mean * 100:>6.0f}% {(g1 + g2) / 2:>8.2f} {base[n] / mean:>8.2f}x  {'ok' if ok1 and ok2 else 'WRONG'}")
    print()
