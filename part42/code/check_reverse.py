#!/usr/bin/env python3
"""Checks the Chapter 42 claims about --mg-scf-to-cf-reverse (lowering scf to cf last to first):
  1. SAME PROGRAM: on every Mountain Goat example of the book that the front end accepts and that has under 400 lines, the output of --lower-affine --mg-scf-to-cf-reverse is byte-for-byte the output of
     --lower-affine --convert-scf-to-cf (so nothing downstream can differ);
  2. NOT ONLY PLAIN LOOPS: a hand-written function with a loop that has a result, an scf.if with results, an scf.while, nested loops, and a loop that uses earlier results lowers to the same text
     and RUNS to the values worked out by hand (10, 1000, 128, 153, 10153);
  3. SAME OUTPUT WHEN RUN: three real programs (an attention example, the tiny transformer, the bigram training run) print the same thing with and without --reverse-loops;
  4. THE COST IS LINEAR (and one function of 3000 loops lowers to the same text), MEASURED IN INSTRUCTIONS (callgrind, exact and repeatable): in one function of n loops, the cost of moving operations between blocks (ilist_traits::transferNodesFromList)
     grows by 4x per doubling under --convert-scf-to-cf and by at most 2.3x under --mg-scf-to-cf-reverse, where it is under 5% of the program's instructions at 2000 loops.
Environment variables (CHK_*) change an input; mutation.py sets them to check that each claim can fail.   Usage: check_reverse.py     Exit status 0 only if all pass."""
import glob, os, re, subprocess, sys, tempfile
here = os.path.dirname(os.path.abspath(__file__)); root = os.path.join(here, "..", ".."); E = os.environ.get
OPT = E("MG_OPT") or os.path.join(here, "build", "mg-opt"); W = tempfile.mkdtemp(prefix="ch42c_")
REV = E("CHK_REVERSE", "--mg-scf-to-cf-reverse"); STD = "--convert-scf-to-cf"
failures = 0
def report(ok, name, detail=""):
    global failures; failures += not ok
    print(f"  {'ok  ' if ok else 'FAIL'} {name}" + ("" if ok else f"\n       {detail}"))
def sh(*a, **k): return subprocess.run(list(a), capture_output=True, text=True, **k)
# ---- 1
print("-- 1. same program on the book's examples")
same = diff = skipped = 0; bad = []
for f in sorted(glob.glob(root + "/part*/code/examples/*.mg") + glob.glob(root + "/tour/code/*.mg")):
    if sum(1 for _ in open(f)) >= 400: skipped += 1; continue
    m = sh(sys.executable, os.path.join(here, "mgfront.py"), f)
    if m.returncode: skipped += 1; continue
    open(W + "/x.mlir", "w").write(m.stdout); a = sh(OPT, W + "/x.mlir", "--convert-mg-to-affine")
    if a.returncode: skipped += 1; continue
    open(W + "/y.mlir", "w").write(a.stdout); r = [sh(OPT, W + "/y.mlir", "--lower-affine", p) for p in (STD, REV)]
    if r[0].returncode == 0 and r[1].returncode == 0 and r[0].stdout == r[1].stdout: same += 1
    else: diff += 1; bad.append(os.path.relpath(f, root))
report(same >= 100 and diff == 0, f"{same} programs lower to byte-identical IR with --mg-scf-to-cf-reverse and --convert-scf-to-cf, {diff} differ ({skipped} skipped: 400 lines or more, or rejected by the front end)", ", ".join(bad[:5]))
# ---- 2
print("-- 2. structured control flow that is not a plain run of loops")
edge = os.path.join(here, "examples", "edge_cases.mlir"); outs = []
for p in (STD, REV):
    r = sh(OPT, edge, p, "--convert-arith-to-llvm", "--convert-func-to-llvm", "--reconcile-unrealized-casts", "-o", f"{W}/e{p}.mlir"); outs.append(r.returncode)
report(outs == [0, 0] and open(f"{W}/e{STD}.mlir").read() == open(f"{W}/e{REV}.mlir").read(), "loop with result, scf.if, scf.while, nested loops: the same text from both lowerings", f"exit codes {outs}")
sh("mlir-translate-18", "--mlir-to-llvmir", f"{W}/e{REV}.mlir", "-o", W + "/e.ll")
sh("clang-18", W + "/e.ll", "-o", W + "/e.exe", "-L/usr/lib/llvm-18/lib", "-lmlir_c_runner_utils", "-lm", "-Wl,-rpath,/usr/lib/llvm-18/lib")
got = sh(W + "/e.exe").stdout.split()
report(got == ["10", "1000", "128", "153", "10153"], "the lowered program prints 10, 1000, 128, 153, 10153 (worked out by hand)", f"got {got}")
# ---- 3
print("-- 3. real programs print the same with and without --reverse-loops")
MGC = os.path.join(here, "mgc"); env = dict(os.environ, MG_OPT=OPT); progs = [os.path.join(root, p) for p in ("part29/code/examples/08_self_attention_block.mg", "part30/code/examples/03_tiny_transformer.mg", "part31/code/examples/04_training.mg")]
progs = [p for p in progs if os.path.exists(p)]
res = []
for p in progs:
    a = sh(MGC, "run", p, env=env); b = sh(MGC, "run", p, "--reverse-loops", env=env)
    norm = lambda s: re.sub(r"base@ = 0x[0-9a-f]+", "base@ = 0x", s)
    res.append((os.path.basename(p), a.returncode == 0 and b.returncode == 0 and norm(a.stdout) == norm(b.stdout) and len(a.stdout) > 20))
report(len(res) == 3 and all(ok for _, ok in res), "three programs print identical output: " + ", ".join(n for n, _ in res), str(res))
# ---- 4
print("-- 4. cost in instructions (callgrind): the splitting cost is quadratic under convert-scf-to-cf, linear under the reverse pass")
def gen(n):
    out = ["module {", "  func.func @f(%a: memref<4xf64>, %b: memref<4xf64>) {"]
    for i in range(n): out.append(f"    affine.for %i{i} = 0 to 4 {{\n      %x{i} = affine.load %a[%i{i}] : memref<4xf64>\n      affine.store %x{i}, %b[%i{i}] : memref<4xf64>\n    }}")
    return "\n".join(out + ["    return", "  }", "}"]) + "\n"
def profile(n, lowering):
    src = f"{W}/g.mlir"; open(src, "w").write(gen(n)); cg = f"{W}/cg.out"
    subprocess.run(["valgrind", "--tool=callgrind", f"--callgrind-out-file={cg}", OPT, src, "--lower-affine", lowering, "-o", "/dev/null"], capture_output=True, check=True)
    text = sh("callgrind_annotate", cg).stdout; tot = tr = 0
    for l in text.split("\n"):
        m = re.match(r"\s*([\d,]+) \(\s*[\d.]+%\)\s+(.*)", l)
        if not m: continue
        ir = int(m.group(1).replace(",", ""))
        if "PROGRAM TOTALS" in m.group(2): tot = ir
        elif "ilist_traits<mlir::Operation>::transferNodesFromList" in m.group(2): tr += ir
    return tot, tr
open(W + "/big.mlir", "w").write(gen(3000)); big = [sh(OPT, W + "/big.mlir", "--lower-affine", p).stdout for p in (STD, REV)]
report(len(big[0]) > 10**6 and big[0] == big[1], "one function of 3000 loops: byte-identical IR from both lowerings (%d bytes)" % len(big[0]))
sizes = (500, 1000, 2000)
std = {n: profile(n, STD) for n in sizes}; rev = {n: profile(n, REV) for n in sizes}
gs = [std[b][1] / max(std[a][1], 1) for a, b in ((500, 1000), (1000, 2000))]; gr = [rev[b][1] / max(rev[a][1], 1) for a, b in ((500, 1000), (1000, 2000))]
report(all(3.9 <= g <= 4.1 for g in gs), "convert-scf-to-cf: transferNodesFromList grows %s per doubling (4 = quadratic)" % " and ".join("x%.2f" % g for g in gs))
report(all(g <= 2.3 for g in gr), "last to first: transferNodesFromList grows %s per doubling (2 = linear)" % " and ".join("x%.2f" % g for g in gr), "")
share = rev[2000][1] / rev[2000][0]
report(share < 0.05, "last to first: block splitting is %.1f%% of the instructions at 2000 loops (convert-scf-to-cf: %.0f%%)" % (100 * share, 100 * std[2000][1] / std[2000][0]))
report(rev[2000][0] <= 1.05 * std[2000][0], "last to first costs at most 5%% more in all at 2000 loops (one conversion per statement): %d million instructions against %d million" % (rev[2000][0] // 10**6, std[2000][0] // 10**6))
print("all checks pass" if not failures else f"{failures} CHECK(S) FAILED"); sys.exit(1 if failures else 0)
