#!/usr/bin/env python3
"""Puts each chapter's picture under its page's title (once; running it again changes nothing). Chapter pages get assets/goats/ch-NN.svg; the tour, the background page and Getting Started get theirs."""
import glob, os, re
root = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
def alt(svg): return re.search(r"<title[^>]*>(.*?)</title>", open(svg).read()).group(1)
def add(md, name, rel):
    text = open(md).read()
    if "assets/goats/" in text: return 0
    svg = os.path.join(root, "assets", "goats", name + ".svg"); lines = text.split("\n")
    i = next(k for k, l in enumerate(lines) if l.startswith("# "))
    lines[i + 1:i + 1] = ["", f'<p style="text-align:center"><img src="{rel}assets/goats/{name}.svg" alt="{alt(svg)}" style="max-width:100%;height:auto;border-radius:6px"></p>']
    open(md, "w").write("\n".join(lines)); return 1
n = 0
for md in sorted(glob.glob(os.path.join(root, "part*", "*.md"))):
    m = re.match(r"(\d+)-", os.path.basename(md))
    if m: n += add(md, f"ch-{int(m.group(1)):02d}", "../")
n += add(os.path.join(root, "tour", "language-tour.md"), "tour", "../") + add(os.path.join(root, "background.md"), "background", "") + add(os.path.join(root, "getting-started.md"), "start", "")
print("added to", n, "pages")
