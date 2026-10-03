#!/usr/bin/env python3
"""Chapter 44: reads bench_out_1.txt and bench_out_2.txt (two complete passes of run_bench.sh) and prints, for each loop order, compiler setting and size, the ratio of the median time with --fast-math
to the median time without (below 1 = faster with the flags), once per pass, and how many result elements differ in their bits. Output: summary_out.txt"""
import re, sys
def rows(f):
    out = {}
    for l in open(f):
        m = re.match(r"(\S+, .*?, (?:plain|--fast-math))\s+(\d+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+(\S+)\s+(.*)", l.strip())
        if m: out[(m.group(1), int(m.group(2)))] = (float(m.group(4)), m.group(7), m.group(6))
    return out
a, b = rows("bench_out_1.txt"), rows("bench_out_2.txt")
print("median time with --fast-math / median time without (below 1 = faster with the flags); two complete passes; pinned core")
print(f"{'variant':30} {'N':>4} {'pass 1':>7} {'pass 2':>7}   {'elements differing in their bits (of N*N)':>44}   largest error plain -> flags")
for k in sorted(a):
    if k[0].endswith("plain"):
        f = (k[0].replace("plain", "--fast-math"), k[1])
        print(f"{k[0].replace(', plain', ''):30} {k[1]:>4} {a[f][0] / a[k][0]:>7.2f} {b[f][0] / b[k][0]:>7.2f}   {a[f][1] + ' of ' + str(k[1] * k[1]):>44}   {a[k][2]} -> {a[f][2]}")
