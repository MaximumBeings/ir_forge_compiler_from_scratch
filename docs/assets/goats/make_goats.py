#!/usr/bin/env python3
"""Writes one mountain-goat picture per chapter (ch-01.svg ... ch-43.svg, plus tour.svg, background.svg, start.svg). Every picture is generated from a seed: its own mountain ridges, sky, weather,
palette (colour or black and white), and one to three goats in different poses. Nothing is random at run time, so running this again rewrites identical files.   Usage: ./make_goats.py"""
import math, os, random
here = os.path.dirname(os.path.abspath(__file__))
W, H = 800, 300
PAL = {
 "dawn":    dict(sky=("#f7c9a9", "#fbe8cf"), far="#c9a5b8", mid="#9a7f9c", near="#6d5b7b", shade="#54466a", snow="#fff6ee", goat="#fffaf3", goat2="#eadfd3", line="#3a2e3f", sun="#ffd9a0", ground="#4a3d5a"),
 "noon":    dict(sky=("#6fb1e6", "#cfe8fa"), far="#a3b6cc", mid="#7a90ab", near="#58708c", shade="#43586f", snow="#f7fbff", goat="#fdfeff", goat2="#e3eaf2", line="#2b3441", sun="#fff7c2", ground="#3f5368"),
 "sunset":  dict(sky=("#5a3a73", "#f08a4b"), far="#8b5a7c", mid="#5e3d66", near="#3e2a50", shade="#2d1f3d", snow="#ffd9c0", goat="#fff0e4", goat2="#e2c6b6", line="#241633", sun="#ffcf7a", ground="#2d1f3d"),
 "night":   dict(sky=("#0b1233", "#2a3a6e"), far="#33456f", mid="#26355c", near="#1b2745", shade="#121b33", snow="#dfe9ff", goat="#eef3ff", goat2="#b9c6e6", line="#0b1233", sun="#f4f1d0", ground="#121b33"),
 "storm":   dict(sky=("#4a525d", "#9aa3ad"), far="#7d8794", mid="#5e6874", near="#464f5b", shade="#343b46", snow="#e9eef3", goat="#f6f8fa", goat2="#d3dae1", line="#232932", sun="#d6dce2", ground="#343b46"),
 "autumn":  dict(sky=("#e9b36f", "#fae6bf"), far="#b58a6c", mid="#8c654f", near="#6a4a3a", shade="#51372c", snow="#fff3dc", goat="#fffaf0", goat2="#e8d8c0", line="#33241c", sun="#fff0b0", ground="#51372c"),
 "spring":  dict(sky=("#8fd0f0", "#e5f6e0"), far="#9dbfae", mid="#6f9c85", near="#4f7d68", shade="#3a6150", snow="#fbfffb", goat="#ffffff", goat2="#e1ede6", line="#26382f", sun="#fffbc4", ground="#3a6150"),
 "winter":  dict(sky=("#b6c9db", "#eef4f9"), far="#b9c7d6", mid="#93a5b8", near="#6e8196", shade="#566a80", snow="#ffffff", goat="#fbfdff", goat2="#dde6ee", line="#2b3a4a", sun="#ffffff", ground="#566a80"),
 "desert":  dict(sky=("#f0b07c", "#fcebc9"), far="#d2a07e", mid="#b57a5a", near="#8f5a42", shade="#6f4331", snow="#fff1de", goat="#fff8ee", goat2="#e8d5bd", line="#3a2218", sun="#fff0c0", ground="#6f4331"),
 "bw":      dict(sky=("#ffffff", "#e6e6e6"), far="#c9c9c9", mid="#9a9a9a", near="#6b6b6b", shade="#4a4a4a", snow="#ffffff", goat="#ffffff", goat2="#dcdcdc", line="#111111", sun="#ffffff", ground="#4a4a4a"),
 "inkdark": dict(sky=("#1a1a1a", "#4d4d4d"), far="#6b6b6b", mid="#4a4a4a", near="#2e2e2e", shade="#1c1c1c", snow="#f2f2f2", goat="#fafafa", goat2="#cfcfcf", line="#000000", sun="#ffffff", ground="#1c1c1c"),
 "sepia":   dict(sky=("#e8d6b5", "#f6ecd6"), far="#c4a982", mid="#a08460", near="#7a6244", shade="#5b4730", snow="#fffaf0", goat="#fffaf0", goat2="#e6d6b8", line="#3a2c1a", sun="#fff4d6", ground="#5b4730"),
 "blueprint": dict(sky=("#123a73", "#2c64b0"), far="#4a7fc4", mid="#366ab0", near="#24528f", shade="#173d70", snow="#e8f1ff", goat="#f4f8ff", goat2="#c3d6f2", line="#0a2347", sun="#e8f1ff", ground="#173d70"),
}
ORDER = ["dawn", "noon", "sunset", "night", "storm", "autumn", "spring", "bw", "winter", "desert", "sepia", "inkdark", "blueprint"]
def ridge(rng, base, amp, n=7, rough=0.55):
    """midpoint-displacement ridge across the picture: list of (x, y)."""
    pts = [(-20, base + rng.uniform(-amp, amp) * 0.4), (W + 20, base + rng.uniform(-amp, amp) * 0.4)]
    a = amp
    for _ in range(n):
        out = []
        for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
            out += [(x0, y0), ((x0 + x1) / 2, (y0 + y1) / 2 + rng.uniform(-a, a))]
        pts = out + [pts[-1]]; a *= rough
    return pts
def height(pts, x):
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        if x0 <= x <= x1: return y0 + (y1 - y0) * (x - x0) / max(x1 - x0, 1e-9)
    return pts[-1][1]
def poly(pts, close_y=H + 5): return "M" + " L".join(f"{x:.0f},{y:.0f}" for x, y in pts) + f" L{W + 20},{close_y} L-20,{close_y} Z"
def goat(x, y, s, flip, pose, c, kid=False):
    """one goat standing with its feet at (x, y); faces right unless flip; pose in stand graze look walk leap rest."""
    L = c["line"]; lw = 1.7 / s; bodyy = -38; dy = 0; rot = 0; head = 0
    legs = {"stand": [(-18, 0), (-10, 0), (14, 0), (22, 0)], "graze": [(-18, 0), (-10, 0), (14, 0), (22, 0)], "look": [(-18, 0), (-10, 0), (14, 0), (22, 0)],
            "walk": [(-24, -6), (-10, 0), (8, 4), (26, -8)], "leap": [(-30, -4), (-22, -10), (30, -20), (38, -12)], "rest": [(-14, 0), (-4, 0), (14, 0), (24, 0)]}[pose]
    if pose == "graze": head = 58
    if pose == "look": head = -22
    if pose == "leap": rot = -14; dy = -6
    if pose == "rest": dy = 14
    parts = []
    # legs: (hind far, hind near, front near, front far) as thin polygons from the body down to the hoof
    for i, (lx, lo) in enumerate(legs):
        col = c["goat2"] if i in (0, 3) else c["goat"]; top = (-30 + dy) if pose != "rest" else (-24 + dy)
        foot = (lx + lo * 0.0, -2 + (lo if pose in ("walk", "leap") else 0))
        if pose == "rest": foot = (lx + (8 if i > 1 else -8), -3)
        hx = lx + (lo * 0.9 if pose in ("walk", "leap") else 0)
        parts.append(f'<polygon points="{lx - 3.5:.1f},{top} {lx + 3.5:.1f},{top} {hx + 2.5:.1f},{foot[1] - 4} {hx - 2.5:.1f},{foot[1] - 4}" fill="{col}" stroke="{L}" stroke-width="{lw:.2f}" stroke-linejoin="round"/>')
        parts.append(f'<rect x="{hx - 3:.1f}" y="{foot[1] - 5}" width="6" height="5" rx="1" fill="{L}"/>')
    parts.append(f'<path d="M-30,{bodyy + dy - 6} C-40,{bodyy + dy - 14} -42,{bodyy + dy - 2} -34,{bodyy + dy + 4}" fill="none" stroke="{L}" stroke-width="{2.4 / s:.2f}" stroke-linecap="round"/>')
    parts.append(f'<ellipse cx="0" cy="{bodyy + dy}" rx="31" ry="15.5" fill="{c["goat"]}" stroke="{L}" stroke-width="{lw:.2f}"/>')
    parts.append(f'<path d="M-24,{bodyy + dy + 6} Q0,{bodyy + dy + 15} 22,{bodyy + dy + 8}" fill="none" stroke="{c["goat2"]}" stroke-width="{3 / s:.2f}" opacity=".8"/>')
    hx0, hy0 = 22, bodyy + dy - 8
    neck = f'<polygon points="{hx0 - 6},{hy0 + 8} {hx0 + 10},{hy0 - 2} {hx0 + 18},{hy0 - 14} {hx0 + 4},{hy0 - 18} {hx0 - 8},{hy0 - 10}" fill="{c["goat"]}" stroke="{L}" stroke-width="{lw:.2f}" stroke-linejoin="round"/>'
    hd = (f'<g transform="rotate({head} {hx0 + 6} {hy0 - 6}) translate({hx0 + 12} {hy0 - 22})">'
          f'<path d="M2,-8 C-6,-30 4,-42 16,-46" fill="none" stroke="{L}" stroke-width="{3.6 / s:.2f}" stroke-linecap="round"/>'
          f'<path d="M8,-8 C6,-30 16,-40 26,-38" fill="none" stroke="{L}" stroke-width="{3.6 / s:.2f}" stroke-linecap="round"/>'
          f'<polygon points="-4,-4 -16,-8 -6,4" fill="{c["goat2"]}" stroke="{L}" stroke-width="{lw:.2f}"/>'
          f'<polygon points="-2,-8 22,-10 34,2 28,12 8,12 -4,6" fill="{c["goat"]}" stroke="{L}" stroke-width="{lw:.2f}" stroke-linejoin="round"/>'
          f'<polygon points="22,12 28,12 24,30 16,14" fill="{c["goat2"]}" stroke="{L}" stroke-width="{lw:.2f}" stroke-linejoin="round"/>'
          f'<circle cx="14" cy="-1" r="2" fill="{L}"/><circle cx="32" cy="3" r="1.8" fill="{L}"/></g>')
    parts += [neck, hd]
    sy = s * (0.62 if kid else 1.0)
    return f'<g transform="translate({x:.0f} {y:.0f}) rotate({rot if not flip else -rot}) scale({-sy if flip else sy} {sy})">' + "".join(parts) + "</g>"
def cloud(x, y, k, col, op=.85):
    return f'<g fill="{col}" opacity="{op}"><ellipse cx="{x}" cy="{y}" rx="{34 * k:.0f}" ry="{11 * k:.0f}"/><ellipse cx="{x - 20 * k:.0f}" cy="{y + 3}" rx="{22 * k:.0f}" ry="{9 * k:.0f}"/><ellipse cx="{x + 22 * k:.0f}" cy="{y + 4}" rx="{24 * k:.0f}" ry="{8 * k:.0f}"/></g>'
def bird(x, y, k, col): return f'<path d="M{x},{y} q{5 * k:.0f},{-6 * k:.0f} {10 * k:.0f},0 q{5 * k:.0f},{-6 * k:.0f} {10 * k:.0f},0" fill="none" stroke="{col}" stroke-width="1.6" stroke-linecap="round"/>'
def pine(x, y, k, col): return f'<polygon points="{x},{y - 34 * k:.0f} {x - 9 * k:.0f},{y - 10 * k:.0f} {x - 4 * k:.0f},{y - 10 * k:.0f} {x - 12 * k:.0f},{y} {x + 12 * k:.0f},{y} {x + 4 * k:.0f},{y - 10 * k:.0f} {x + 9 * k:.0f},{y - 10 * k:.0f}" fill="{col}"/>'
def scene(n, theme, title, desc=None):
    rng = random.Random(1000 + n * 7919); c = PAL[theme]; o = []; gid = f"g{n}"
    o.append(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" role="img" aria-labelledby="t{n}"><title id="t{n}">{title}</title>')
    o.append(f'<defs><linearGradient id="{gid}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{c["sky"][0]}"/><stop offset="1" stop-color="{c["sky"][1]}"/></linearGradient></defs>')
    o.append(f'<rect width="{W}" height="{H}" fill="url(#{gid})"/>')
    mono = theme in ("bw", "inkdark", "sepia")
    # sky furniture
    if theme in ("night", "inkdark", "blueprint"):
        for _ in range(48): o.append(f'<circle cx="{rng.randint(5, W - 5)}" cy="{rng.randint(5, 150)}" r="{rng.choice([0.8, 1.1, 1.6])}" fill="#ffffff" opacity="{rng.uniform(.5, 1):.2f}"/>')
    sx, sy = rng.choice([rng.randint(70, 220), rng.randint(560, 740)]), rng.randint(36, 90)
    if theme not in ("storm",): o.append(f'<circle cx="{sx}" cy="{sy}" r="{rng.randint(15, 26)}" fill="{c["sun"]}" opacity=".95"/><circle cx="{sx}" cy="{sy}" r="{rng.randint(32, 46)}" fill="{c["sun"]}" opacity=".22"/>')
    for _ in range(rng.randint(2, 5) if theme != "storm" else 7): o.append(cloud(rng.randint(30, W - 30), rng.randint(25, 120), rng.uniform(.7, 1.5), c["snow"] if theme != "night" else "#5a6a99", .55 if theme in ("night", "inkdark") else .8))
    for _ in range(rng.randint(0, 3)): o.append(bird(rng.randint(60, W - 80), rng.randint(40, 130), rng.uniform(.8, 1.4), c["line"]))
    # three ridges
    far = ridge(rng, 172, 100, rough=.6); mid = ridge(rng, 208, 70, rough=.55); near = ridge(rng, 238, 45, rough=.5)
    for pts, col, sc, snowline in ((far, c["far"], c["snow"], 118), (mid, c["mid"], c["snow"], 155), (near, c["near"], c["snow"], 205)):
        o.append(f'<path d="{poly(pts)}" fill="{col}"/>')
        zig = [(x, snowline + rng.uniform(-9, 9)) for x in range(-20, W + 40, 18)]
        cid = f"c{n}{int(snowline)}"
        o.append(f'<clipPath id="{cid}"><path d="M-20,-5 L{W + 20},-5 L' + " L".join(f"{x:.0f},{y:.0f}" for x, y in reversed(zig)) + ' Z"/></clipPath>')
        o.append(f'<path d="{poly(pts)}" fill="{sc}" clip-path="url(#{cid})" opacity=".96"/>')
    # shading wedges on the near ridge
    for _ in range(5):
        x = rng.randint(30, W - 60); y = height(near, x)
        o.append(f'<polygon points="{x},{y:.0f} {x + rng.randint(30, 70)},{y + rng.randint(40, 70):.0f} {x - 6},{H}" fill="{c["shade"]}" opacity=".45"/>')
    # trees on the lower slope
    if theme in ("spring", "autumn", "dawn", "noon", "sunset", "sepia", "storm"):
        for _ in range(rng.randint(5, 12)):
            x = rng.randint(10, W - 10); o.append(pine(x, min(height(near, x) + rng.randint(35, 55), H - 4), rng.uniform(.7, 1.3), c["shade"] if theme != "autumn" else rng.choice(["#a85a2a", "#c98a2e", "#7a4a2a"])))
    # ground line for the goats: the near ridge itself, with a rock shelf
    ground = ridge(rng, 262, 14, n=5)
    o.append(f'<path d="{poly(ground)}" fill="{c["ground"]}"/>')
    # goats
    poses = ["stand", "graze", "look", "walk", "leap", "rest"]; k = rng.choice([1, 1, 2, 2, 3]); xs = []
    for x in rng.sample(range(90, W - 90, 10), 60):
        if all(abs(x - p) >= 150 for p in xs) and len(xs) < k: xs.append(x)
    xs.sort()
    big = rng.uniform(1.15, 1.45)
    for i, x in enumerate(xs):
        pose = poses[(n * 5 + i * 2 + rng.randint(0, 5)) % 6]; kid = i > 0 and rng.random() < .45; y = height(ground, x) + 4
        o.append(f'<ellipse cx="{x}" cy="{y + 2:.0f}" rx="38" ry="6" fill="{c["shade"]}" opacity=".7"/>')
        o.append(goat(x, y, big * (0.85 if i else 1), rng.random() < .5, "stand" if kid and pose == "leap" else pose, c, kid))
    # weather
    if theme == "storm":
        x0 = rng.randint(150, 650); o.append(f'<polyline points="{x0},20 {x0 - 12},70 {x0 + 2},72 {x0 - 18},130 {x0 + 14},80 {x0},78 {x0 + 12},20" fill="#fff6a8" opacity=".9"/>')
        for _ in range(60): x, y = rng.randint(0, W), rng.randint(0, H); o.append(f'<line x1="{x}" y1="{y}" x2="{x - 5}" y2="{y + 14}" stroke="#dfe6ee" stroke-width="1" opacity=".5"/>')
    if theme == "winter":
        for _ in range(90): o.append(f'<circle cx="{rng.randint(0, W)}" cy="{rng.randint(0, H)}" r="{rng.choice([1, 1.4, 2])}" fill="#ffffff" opacity=".85"/>')
    if theme == "blueprint":
        for gx in range(0, W + 1, 40): o.append(f'<line x1="{gx}" y1="0" x2="{gx}" y2="{H}" stroke="#ffffff" stroke-width=".4" opacity=".25"/>')
        for gy in range(0, H + 1, 40): o.append(f'<line x1="0" y1="{gy}" x2="{W}" y2="{gy}" stroke="#ffffff" stroke-width=".4" opacity=".25"/>')
    o.append("</svg>")
    return "\n".join(o)
# one entry per picture: (file, theme, alt text)
THEMES = ["dawn", "noon", "sunset", "night", "storm", "autumn", "spring", "bw", "winter", "desert", "sepia", "inkdark", "blueprint"]
def pick(n): return THEMES[(n * 5 + n // 13) % len(THEMES)] if n else "noon"
PAGES = [(f"ch-{n:02d}", pick(n)) for n in range(1, 44)] + [("tour", "spring"), ("background", "sepia"), ("start", "dawn")]
if __name__ == "__main__":
    for i, (name, theme) in enumerate(PAGES, start=1):
        n = i if not name.startswith("ch-") else int(name[3:])
        if not name.startswith("ch-"): n = 100 + i
        text = {"night": "at night", "storm": "in a storm", "winter": "in winter snow", "blueprint": "drawn as a blueprint", "bw": "in black and white", "inkdark": "in black and white at dusk", "sepia": "in sepia", "dawn": "at dawn", "noon": "at midday", "sunset": "at sunset", "autumn": "in autumn", "spring": "in spring", "desert": "above a desert"}[theme]
        open(os.path.join(here, name + ".svg"), "w").write(scene(n, theme, f"Mountain goats on the mountain {text}") + "\n")
    print("wrote", len(PAGES), "pictures")
