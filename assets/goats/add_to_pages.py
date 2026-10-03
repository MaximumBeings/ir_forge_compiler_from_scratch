#!/usr/bin/env python3
"""Puts each chapter's picture under its page's title as a MARKDOWN image (mkdocs rewrites its path for the page's final URL; a raw <img> with a relative path is not rewritten and breaks) (once; running it again changes nothing). Chapter pages get assets/goats/ch-NN.svg; the tour, the background page and Getting Started get theirs."""
import glob, os, re
root = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
def alt(svg): return re.search(r"<title[^>]*>(.*?)</title>", open(svg).read()).group(1)
def add(md, name, rel):
    text = open(md).read()
    if "assets/goats/" in text:       # already there: only refresh the alt text from the picture's title (the picture may have been regenerated)
        new = re.sub(r"!\[[^\]]*\]\(([./]*assets/goats/" + name + r"\.svg)\)", lambda m: f"![{alt(os.path.join(root, 'assets', 'goats', name + '.svg'))}]({m.group(1)})", text)
        if new != text: open(md, "w").write(new)
        return 0
    svg = os.path.join(root, "assets", "goats", name + ".svg"); lines = text.split("\n")
    i = next(k for k, l in enumerate(lines) if l.startswith("# "))
    lines[i + 1:i + 1] = ["", f'![{alt(svg)}]({rel}assets/goats/{name}.svg){{ style="display:block;margin:0 auto;max-width:100%;height:auto;border-radius:6px" }}']
    open(md, "w").write("\n".join(lines)); return 1
n = 0
for md in sorted(glob.glob(os.path.join(root, "part*", "*.md"))):
    m = re.match(r"(\d+)-", os.path.basename(md))
    if m: n += add(md, f"ch-{int(m.group(1)):02d}", "../")
n += add(os.path.join(root, "tour", "language-tour.md"), "tour", "../") + add(os.path.join(root, "background.md"), "background", "") + add(os.path.join(root, "getting-started.md"), "start", "")
print("added to", n, "pages")
