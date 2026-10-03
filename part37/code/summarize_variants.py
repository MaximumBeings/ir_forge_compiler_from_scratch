#!/usr/bin/env python3
"""Summarise variants_out.txt (three passes of the benchmark) as one table: for each variant and size, the three median GFLOP/s, the slowest and fastest of them.
Usage: summarize_variants.py [variants_out.txt]   Output: variants_summary.txt"""
import re, sys, collections
res = collections.OrderedDict()
for l in open(sys.argv[1] if len(sys.argv) > 1 else "variants_out.txt"):
    m = re.match(r"(\w+)(?: \(dynamic sizes\))?\s+N=(\d+)\s+min\s+([\d.]+) ms\s+median\s+([\d.]+) ms\s+([\d.]+) GFLOP/s", l)
    if m: res.setdefault((m.group(1), int(m.group(2))), []).append(float(m.group(5)))
print(f"{'variant':<14} {'N':>4}  median GFLOP/s in each of the three passes    slowest..fastest")
for (v, n), g in res.items(): print(f"{v:<14} {n:>4}  {'  '.join(f'{x:6.2f}' for x in g)}   {min(g):6.2f}..{max(g):6.2f}")
base = {n: sum(g) / len(g) for (v, n), g in res.items() if v == "ijk"}
print()
print("mean of the three passes, relative to ijk at the same N:")
for (v, n), g in res.items(): print(f"  {v:<14} N={n:<4} {sum(g) / len(g):6.2f} GFLOP/s = {sum(g) / len(g) / base[n]:5.2f}x ijk")
