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
def goat(x, y, s, flip, pose, c, kid=False, helmet=False):
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
          f'<circle cx="14" cy="-1" r="2" fill="{L}"/><circle cx="32" cy="3" r="1.8" fill="{L}"/>'
          + (f'<circle cx="17" cy="0" r="30" fill="#cfe9ff" fill-opacity=".22" stroke="#e8f4ff" stroke-width="{2.4 / s:.2f}"/><path d="M-3,-14 A24,24 0 0 1 16,-24" fill="none" stroke="#ffffff" stroke-width="{2.6 / s:.2f}" stroke-linecap="round" opacity=".85"/>' if helmet else "") + '</g>')
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

SPACE = {
 "moon":    dict(far="#9b9b9b", mid="#7a7a7a", near="#5a5a5a", ground="#454545", shade="#2c2c2c", sky=("#000000", "#06070d"), where="on the Moon"),
 "saturn":  dict(far="#c9b88f", mid="#a89870", near="#8a7a58", ground="#6e6046", shade="#4c4230", sky=("#000000", "#0a0a14"), where="on a moon of Saturn"),
 "mars":    dict(far="#c98a6a", mid="#a8654a", near="#864a35", ground="#6a3a2a", shade="#4a281c", sky=("#d9a37a", "#f2d2a8"), where="on Mars"),
 "pluto":   dict(far="#9c8478", mid="#7e665c", near="#5e4a42", ground="#4a3a34", shade="#2e231f", sky=("#000000", "#0b0a12"), where="on Pluto"),
 "mercury": dict(far="#8d8780", mid="#6f6a64", near="#524e49", ground="#3e3a36", shade="#262320", sky=("#000000", "#0a0806"), where="on Mercury"),
 "venus":   dict(far="#b9803f", mid="#9a6630", near="#7a4f25", ground="#5e3b1c", shade="#3f2711", sky=("#c98b2e", "#f1cf86"), where="on Venus, under its clouds"),
 "io":      dict(far="#d9c35a", mid="#b8a040", near="#8f7b2c", ground="#6e5e20", shade="#3f3510", sky=("#000000", "#0a0905"), where="on Io, a moon of Jupiter"),
 "uranus":  dict(far="#b9d3d6", mid="#93b3b8", near="#6e8e93", ground="#52716f", shade="#34504e", sky=("#000000", "#06090c"), where="on Titania, a moon of Uranus"),
 "neptune": dict(far="#e3cfd0", mid="#c4aeb0", near="#9d878a", ground="#7a666a", shade="#4f3f43", sky=("#000000", "#050810"), where="on Triton, a moon of Neptune"),
 "europa":  dict(far="#cfdcea", mid="#a9bdd2", near="#8aa2bd", ground="#6f87a3", shade="#4e647c", sky=("#000000", "#080a12"), where="on Europa, a moon of Jupiter"),
}
def planet(kind, rng, c):
    o = []
    if kind == "moon":      # Earth
        cx, cy, r = rng.randint(520, 700), rng.randint(70, 110), rng.randint(42, 58)
        o.append(f'<clipPath id="pl"><circle cx="{cx}" cy="{cy}" r="{r}"/></clipPath><circle cx="{cx}" cy="{cy}" r="{r}" fill="#2f6fc4"/>')
        o.append(f'<g clip-path="url(#pl)"><ellipse cx="{cx - 15}" cy="{cy - 8}" rx="{r * .4:.0f}" ry="{r * .32:.0f}" fill="#4e9a4e"/><ellipse cx="{cx + 20}" cy="{cy + 14}" rx="{r * .3:.0f}" ry="{r * .22:.0f}" fill="#5aa35a"/><ellipse cx="{cx + 6}" cy="{cy - 22}" rx="{r * .5:.0f}" ry="5" fill="#ffffff" opacity=".75"/><ellipse cx="{cx - 20}" cy="{cy + 20}" rx="{r * .4:.0f}" ry="4" fill="#ffffff" opacity=".7"/><circle cx="{cx + r * .45:.0f}" cy="{cy + r * .3:.0f}" r="{r * 1.05:.0f}" fill="#000" opacity=".4"/></g>')
    elif kind == "mars":    # Phobos and a small sun
        o.append('<circle cx="640" cy="60" r="12" fill="#fff4d6" opacity=".95"/><circle cx="640" cy="60" r="26" fill="#fff4d6" opacity=".25"/><ellipse cx="170" cy="70" rx="16" ry="11" fill="#8a7a6e"/>')
    elif kind == "mercury":   # a huge sun low over the horizon
        o.append('<circle cx="560" cy="175" r="95" fill="#ffd9a0" opacity=".16"/><circle cx="560" cy="175" r="62" fill="#ffe7bd" opacity=".35"/><circle cx="560" cy="175" r="40" fill="#fff6e3"/>')
    elif kind == "venus":     # bands of cloud and a dim sun behind them
        o.append('<circle cx="190" cy="60" r="34" fill="#fff0c0" opacity=".45"/>' + "".join(f'<ellipse cx="{rng.randint(0, W)}" cy="{rng.randint(15, 150)}" rx="{rng.randint(90, 220)}" ry="{rng.randint(5, 12)}" fill="#e3b45a" opacity=".5"/>' for _ in range(9)))
    elif kind == "io":        # Jupiter, huge, rising over a sulphur landscape
        cx, cy, r = 600, 60, 105
        o.append(f'<clipPath id="pl"><circle cx="{cx}" cy="{cy}" r="{r}"/></clipPath><circle cx="{cx}" cy="{cy}" r="{r}" fill="#e9c79a"/><g clip-path="url(#pl)">' + "".join(f'<rect x="{cx - r}" y="{cy - r + k * r / 3.6:.0f}" width="{2 * r}" height="{r / 6.5:.0f}" fill="{col}" opacity=".75"/>' for k, col in enumerate(["#b5703f", "#f3e1c0", "#c98450", "#efd6ad", "#a65f33", "#f0dcb8", "#c47a4a", "#e6c797", "#b5703f"])) + f'<ellipse cx="{cx - r * .25:.0f}" cy="{cy + r * .35:.0f}" rx="{r * .2:.0f}" ry="{r * .12:.0f}" fill="#b8472f"/></g>')
    elif kind == "uranus":    # a pale cyan disc with a thin tilted ring system
        cx, cy, r = 560, 100, 50
        o.append(f'<ellipse cx="{cx}" cy="{cy}" rx="{r * 1.9:.0f}" ry="{r * .22:.0f}" fill="none" stroke="#cfe9ee" stroke-width="3" opacity=".8" transform="rotate(-72 {cx} {cy})"/><circle cx="{cx}" cy="{cy}" r="{r}" fill="#a8dde3"/><circle cx="{cx + 12}" cy="{cy + 8}" r="{r}" fill="#000" opacity=".12"/>')
    elif kind == "neptune":   # deep blue with a dark storm and bright streaks
        cx, cy, r = 520, 95, 52
        o.append(f'<clipPath id="pl"><circle cx="{cx}" cy="{cy}" r="{r}"/></clipPath><circle cx="{cx}" cy="{cy}" r="{r}" fill="#2f55c9"/><g clip-path="url(#pl)"><ellipse cx="{cx - 14}" cy="{cy + 6}" rx="14" ry="8" fill="#1a2f8a"/><ellipse cx="{cx + 6}" cy="{cy - 18}" rx="26" ry="2.5" fill="#ffffff" opacity=".7"/><ellipse cx="{cx + 14}" cy="{cy + 20}" rx="20" ry="2" fill="#ffffff" opacity=".6"/><circle cx="{cx + 16}" cy="{cy + 12}" r="{r * 1.05:.0f}" fill="#000" opacity=".4"/></g>')
    elif kind in ("saturn", "pluto", "europa"):
        cx, cy, r = rng.randint(480, 680), rng.randint(80, 120), {"saturn": 54, "pluto": 34, "europa": 62}[kind]
        if kind == "saturn":
            o.append(f'<ellipse cx="{cx}" cy="{cy}" rx="{r * 2.1:.0f}" ry="{r * .55:.0f}" fill="none" stroke="#d8c48e" stroke-width="9" opacity=".9" transform="rotate(-18 {cx} {cy})"/><ellipse cx="{cx}" cy="{cy}" rx="{r * 1.75:.0f}" ry="{r * .46:.0f}" fill="none" stroke="#b79f69" stroke-width="5" opacity=".9" transform="rotate(-18 {cx} {cy})"/>')
            o.append(f'<clipPath id="pl"><circle cx="{cx}" cy="{cy}" r="{r}"/></clipPath><circle cx="{cx}" cy="{cy}" r="{r}" fill="#e3cf98"/><g clip-path="url(#pl)">' + "".join(f'<rect x="{cx - r}" y="{cy - r + k * r / 3.5:.0f}" width="{2 * r}" height="{r / 7:.0f}" fill="{col}" opacity=".7"/>' for k, col in enumerate(["#c9aa6c", "#efdcae", "#bf9c5c", "#e8d3a0", "#c4a468", "#e3cf98", "#b99655"])) + '</g>')
        elif kind == "pluto":   # Charon big and grey, a tiny sun
            o.append(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="#8f8a85"/><circle cx="{cx - 8}" cy="{cy - 6}" r="9" fill="#6e6a66"/><circle cx="{cx + 12}" cy="{cy + 10}" r="6" fill="#77736f"/><circle cx="{cx - r + 10}" cy="{cy - r + 8}" r="3" fill="#fff4d6"/><circle cx="130" cy="50" r="5" fill="#fff4d6"/><circle cx="130" cy="50" r="11" fill="#fff4d6" opacity=".25"/>')
        else:                   # Jupiter over Europa
            o.append(f'<clipPath id="pl"><circle cx="{cx}" cy="{cy}" r="{r}"/></clipPath><circle cx="{cx}" cy="{cy}" r="{r}" fill="#e9c79a"/><g clip-path="url(#pl)">' + "".join(f'<rect x="{cx - r}" y="{cy - r + k * r / 3.2:.0f}" width="{2 * r}" height="{r / 6:.0f}" fill="{col}" opacity=".75"/>' for k, col in enumerate(["#b5703f", "#f3e1c0", "#c98450", "#efd6ad", "#a65f33", "#f0dcb8", "#c47a4a", "#e6c797"])) + f'<ellipse cx="{cx + r * .3:.0f}" cy="{cy + r * .25:.0f}" rx="{r * .22:.0f}" ry="{r * .13:.0f}" fill="#b8472f"/></g>')
    return "".join(o)
def space_scene(n, body, title):
    rng = random.Random(5000 + n * 7919); P = SPACE[body]; o = []
    c = dict(PAL["bw"]); c.update(goat="#ffffff", goat2="#d9dde6", line="#12151c", ground=P["ground"], shade=P["shade"])
    o.append(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" role="img" aria-labelledby="t{n}"><title id="t{n}">{title}</title>')
    o.append(f'<defs><linearGradient id="g{n}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{P["sky"][0]}"/><stop offset="1" stop-color="{P["sky"][1]}"/></linearGradient></defs><rect width="{W}" height="{H}" fill="url(#g{n})"/>')
    if body not in ("mars", "venus"):
        for _ in range(110): o.append(f'<circle cx="{rng.randint(3, W - 3)}" cy="{rng.randint(3, 190)}" r="{rng.choice([0.7, 0.9, 1.2, 1.7])}" fill="#ffffff" opacity="{rng.uniform(.4, 1):.2f}"/>')
    o.append(planet(body, rng, P))
    far = ridge(rng, 185, 60, rough=.6); mid = ridge(rng, 215, 45, rough=.55); near = ridge(rng, 240, 30, rough=.5)
    for pts, col in ((far, P["far"]), (mid, P["mid"]), (near, P["near"])): o.append(f'<path d="{poly(pts)}" fill="{col}"/>')
    ground = ridge(rng, 262, 10, n=5); o.append(f'<path d="{poly(ground)}" fill="{P["ground"]}"/>')
    for _ in range(9):      # craters on the foreground
        x, y = rng.randint(20, W - 20), rng.randint(272, 294); rx = rng.randint(16, 46)
        o.append(f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{rx // 5 + 2}" fill="{P["shade"]}" opacity=".75"/><ellipse cx="{x - 3}" cy="{y - 2}" rx="{rx - 5}" ry="{max(rx // 5 - 1, 1)}" fill="{P["ground"]}"/>')
    if body == "pluto": o.append('<path d="M340,282 C320,262 360,256 372,270 C384,256 424,262 404,282 C392,294 380,296 372,300 C362,296 350,294 340,282 Z" fill="#e9dccf" opacity=".85"/>')
    if body == "europa":
        for _ in range(7): x = rng.randint(0, W); o.append(f'<polyline points="{x},262 {x + rng.randint(-60, 60)},{rng.randint(272, 280)} {x + rng.randint(-120, 120)},{H}" fill="none" stroke="#5b4a3a" stroke-width="1.4" opacity=".6"/>')
    k = rng.choice([1, 2, 2, 3]); xs = []
    for x in rng.sample(range(90, W - 90, 10), 60):
        if all(abs(x - p) >= 150 for p in xs) and len(xs) < k: xs.append(x)
    xs.sort(); big = rng.uniform(1.15, 1.4); poses = ["stand", "look", "walk", "leap", "rest", "graze"]
    for i, x in enumerate(xs):
        y = height(ground, x) + 6; kid = i > 0 and rng.random() < .4; pose = poses[(n + i * 2 + rng.randint(0, 5)) % 6]
        o.append(f'<ellipse cx="{x}" cy="{y + 2:.0f}" rx="38" ry="6" fill="#000" opacity=".5"/>')
        o.append(goat(x, y, big * (0.85 if i else 1), rng.random() < .5, "stand" if kid and pose == "leap" else pose, c, kid, helmet=True))
    o.append("</svg>")
    return "\n".join(o)

# one entry per picture: (file, theme, alt text)
THEMES = ["dawn", "noon", "sunset", "night", "storm", "autumn", "spring", "bw", "winter", "desert", "sepia", "inkdark", "blueprint"]
def pick(n): return THEMES[(n * 5 + n // 13) % len(THEMES)] if n else "noon"
SPACE_PAGES = {"ch-04": "moon", "ch-06": "mercury", "ch-08": "saturn", "ch-10": "venus", "ch-13": "mars", "ch-15": "io", "ch-17": "pluto", "ch-19": "uranus", "ch-21": "europa", "ch-23": "neptune", "ch-25": "moon", "ch-27": "mercury",
               "ch-29": "saturn", "ch-31": "venus", "ch-33": "mars", "ch-35": "io", "ch-37": "uranus", "ch-39": "neptune", "ch-40": "moon", "ch-41": "pluto", "ch-42": "saturn", "ch-43": "europa", "ch-44": "mars", "ch-45": "uranus", "tour": "moon", "background": "venus"}
PAGES = [(f"ch-{n:02d}", pick(n)) for n in range(1, 46)] + [("tour", "spring"), ("background", "sepia"), ("start", "dawn")]
if __name__ == "__main__":
    for i, (name, theme) in enumerate(PAGES, start=1):
        n = i if not name.startswith("ch-") else int(name[3:])
        if not name.startswith("ch-"): n = 100 + i
        text = {"night": "at night", "storm": "in a storm", "winter": "in winter snow", "blueprint": "drawn as a blueprint", "bw": "in black and white", "inkdark": "in black and white at dusk", "sepia": "in sepia", "dawn": "at dawn", "noon": "at midday", "sunset": "at sunset", "autumn": "in autumn", "spring": "in spring", "desert": "above a desert"}[theme]
        if name in SPACE_PAGES:
            body = SPACE_PAGES[name]; svg = space_scene(n, body, f"Mountain goats in space helmets {SPACE[body]['where']}")
        else: svg = scene(n, theme, f"Mountain goats on the mountain {text}")
        if name == "start":      # Getting Started gets its own picture: a trail signpost at the foot of the climb
            c = PAL[theme]; post = (f'<g transform="translate(690 258)"><rect x="-3" y="-70" width="6" height="70" fill="#6b4a2f"/><polygon points="-4,-68 40,-68 52,-60 40,-52 -4,-52" fill="#c89a62" stroke="#4a3320" stroke-width="1.5"/>'
                                    f'<polygon points="4,-46 -38,-46 -50,-38 -38,-30 4,-30" fill="#d8b07a" stroke="#4a3320" stroke-width="1.5"/><text x="2" y="-56" font-family="sans-serif" font-size="9" font-weight="bold" fill="#3a2515" text-anchor="middle">START</text>'
                                    f'<text x="-22" y="-35" font-family="sans-serif" font-size="8" fill="#3a2515" text-anchor="middle">SUMMIT</text></g>')
            svg = svg.replace("</svg>", post + "</svg>").replace("Mountain goats on the mountain at dawn", "Mountain goats and a trail signpost marked START at the foot of the climb, at dawn")
        open(os.path.join(here, name + ".svg"), "w").write(svg + "\n")
    print("wrote", len(PAGES), "pictures")
