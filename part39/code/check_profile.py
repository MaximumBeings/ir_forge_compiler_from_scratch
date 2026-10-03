#!/usr/bin/env python3
"""Checks the Chapter 39 claims by running valgrind's callgrind on mg-opt (instruction counts are exact and repeatable, so these checks are not timing checks):
  1. in ONE function, the instructions spent in ilist_traits<Operation>::transferNodesFromList grow by 4x each time the number of loops doubles (quadratic) while the program's
     total grows by less than 2.3x (about linear);
  2. that function is called by Block::splitBlock (and by nothing that matters for the totals);
  3. with the same loops in functions of 100, the function's cost grows by about 2x per doubling (linear);
  4. after --mg-outline-loops, the function (and splitBlock) are no longer in the profile at all.
Environment variables (CHK_*) change an input; claims_mutation.py sets them to check that each claim can fail.   Usage: check_profile.py   Exit status 0 only if all pass."""
import os, re, subprocess, sys, tempfile
here = os.path.dirname(os.path.abspath(__file__)); E = os.environ.get
OPT = E("MG_OPT") or os.path.join(here, "..", "..", "part38", "code", "build", "mg-opt"); W = tempfile.mkdtemp(prefix="ch39c_")
PER, OUTLINE, LOWER = int(E("CHK_PER", "100")), E("CHK_OUTLINE", "--mg-outline-loops"), E("CHK_PASSES", "--lower-affine --convert-scf-to-cf").split()
failures = 0
def report(ok, name, detail=""):
    global failures; failures += not ok
    print(f"  {'ok  ' if ok else 'FAIL'} {name}" + ("" if ok else f"\n       {detail}"))
def gen(n, per):
    out = ["module {"]; left = n
    for f in range((n + per - 1) // per):
        m = min(per, left); left -= m; out.append(f"  func.func @f{f}(%a: memref<4xf64>, %b: memref<4xf64>) {{")
        for i in range(m): out.append(f"    affine.for %i{i} = 0 to 4 {{\n      %x{i} = affine.load %a[%i{i}] : memref<4xf64>\n      affine.store %x{i}, %b[%i{i}] : memref<4xf64>\n    }}")
        out += ["    return", "  }"]
    return "\n".join(out + ["}"]) + "\n"
def profile(n, per, extra=()):
    src = f"{W}/g.mlir"; open(src, "w").write(gen(n, per)); cg = f"{W}/cg.out"
    subprocess.run(["valgrind", "--tool=callgrind", f"--callgrind-out-file={cg}", OPT, src, *extra, *LOWER, "-o", "/dev/null"], capture_output=True, check=True)
    text = subprocess.run(["callgrind_annotate", cg], capture_output=True, text=True).stdout; tot = 0; tr = 0; split = False
    for l in text.split("\n"):
        m = re.match(r"\s*([\d,]+) \(\s*[\d.]+%\)\s+(.*)", l)
        if not m: continue
        ir = int(m.group(1).replace(",", ""))
        if "PROGRAM TOTALS" in m.group(2): tot = ir
        elif "ilist_traits<mlir::Operation>::transferNodesFromList" in m.group(2): tr += ir
        if "Block::splitBlock" in m.group(2): split = True
    callers = subprocess.run(["callgrind_annotate", "--tree=caller", cg], capture_output=True, text=True).stdout
    return tot, tr, split, callers
sizes = (250, 500, 1000)
one = {n: profile(n, n) for n in sizes}
g = lambda d, i, a, b: d[b][i] / max(d[a][i], 1)
report(all(3.9 <= g(one, 1, a, b) <= 4.1 for a, b in ((250, 500), (500, 1000))), "one function: transferNodesFromList grows %s per doubling (4 = quadratic)" % " and ".join("x%.2f" % g(one, 1, a, b) for a, b in ((250, 500), (500, 1000))), str({n: one[n][1] for n in sizes}))
report(all(g(one, 0, a, b) < 2.3 for a, b in ((250, 500), (500, 1000))), "one function: the whole program grows %s per doubling (about linear)" % " and ".join("x%.2f" % g(one, 0, a, b) for a, b in ((250, 500), (500, 1000))), str({n: one[n][0] for n in sizes}))
callers = one[1000][3]; seg = re.search(r"((?:^.*\n){0,6})^.*\*\s+\?\?\?:llvm::ilist_traits<mlir::Operation>::transferNodesFromList", callers, re.M)
report(seg is not None and "Block::splitBlock" in seg.group(1), "transferNodesFromList is called by Block::splitBlock", (seg.group(1) if seg else "function not found")[-400:])
many = {n: profile(n, PER) for n in sizes}
report(all(g(many, 1, a, b) < 2.3 for a, b in ((250, 500), (500, 1000))), "functions of %d loops: transferNodesFromList grows %s per doubling (2 = linear)" % (PER, " and ".join("x%.2f" % g(many, 1, a, b) for a, b in ((250, 500), (500, 1000)))), str({n: many[n][1] for n in sizes}))
out = {n: profile(n, n, [OUTLINE]) for n in (500, 1000)}
report(all(out[n][1] == 0 and not out[n][2] for n in out), f"after {OUTLINE}: no transferNodesFromList and no splitBlock in the profile (n = 500, 1000)", str({n: (out[n][1], out[n][2]) for n in out}))
print("all checks pass" if failures == 0 else f"{failures} CHECK(S) FAILED"); sys.exit(1 if failures else 0)
