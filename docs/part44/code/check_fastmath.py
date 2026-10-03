#!/usr/bin/env python3
"""Checks the Chapter 44 claims about --mg-set-fastmath and mgc --fast-math:
  1. THE PASS: it puts `fastmath<reassoc,contract>` on every floating-point arith operation (and on nothing else), takes other flags as an option, rejects an unknown flag, and does nothing when not run;
  2. THE DRIVER: mgc is unchanged by default (no flag in the LLVM IR), `--fast-math` puts reassoc and contract on every fadd/fsub/fmul/fdiv, `--fast-math=reassoc` only reassoc;
  3. THE VECTORIZER (clang -O3 -march=sapphirerapids, pinned): the ijk matrix product's dot-product loop is NOT vectorized without the flags (reason: cannot reorder floating-point operations) and IS with them,
     both for sizes known at compile time and for sizes known at run time;
  4. THE DEFAULT IS SAFE ON THE BOOK'S PROGRAMS: on every sixth book example, `--fast-math` at -O2 prints the same numbers as without;
  5. THE NEGATIVE CONTROL: the flag `nnan` is NOT in the default because it can change an answer: at -O2, p >= p for a NaN p prints 0 normally, 0 with reassoc,contract, and 1 with nnan (WRONG on purpose, shown to be why).
Environment variables (CHK_*) change an input; mutation.py edits the pass and the driver to check that each claim can fail.   Usage: check_fastmath.py     Exit status 0 only if all pass."""
import glob, math, os, re, subprocess, sys, tempfile
here = os.path.dirname(os.path.abspath(__file__)); root = os.path.join(here, "..", ".."); E = os.environ.get
OPT = E("MG_OPT") or os.path.join(here, "build", "mg-opt"); MGC = E("CHK_MGC") or os.path.join(here, "mgc"); W = tempfile.mkdtemp(prefix="ch44c_"); CPU = "sapphirerapids"
env = dict(os.environ, MG_OPT=OPT); failures = 0
def report(ok, name, detail=""):
    global failures; failures += not ok
    print(f"  {'ok  ' if ok else 'FAIL'} {name}" + ("" if ok else f"\n       {detail}"))
def sh(*a, **k): return subprocess.run(list(a), capture_output=True, text=True, **k)
# ---- 1
print("-- 1. the pass")
src = W + "/f.mlir"; open(src, "w").write("func.func @f(%a: f64, %b: f64, %c: f64, %i: i32) -> f64 {\n  %m = arith.mulf %a, %b : f64\n  %s = arith.addf %m, %c : f64\n  %d = arith.divf %s, %a : f64\n  %n = arith.negf %d : f64\n  %j = arith.addi %i, %i : i32\n  return %n : f64\n}\n")
default = sh(OPT, src, "--mg-set-fastmath").stdout; plain = sh(OPT, src).stdout
fp = [l for l in default.split("\n") if re.search(r"arith\.(mulf|addf|divf|negf)", l)]; integer = [l for l in default.split("\n") if "arith.addi" in l]
report(len(fp) == 4 and all("fastmath<reassoc,contract>" in l for l in fp) and "fastmath" not in integer[0] and "fastmath" not in plain, "all 4 floating-point operations get fastmath<reassoc,contract>; the integer addition and the unprocessed file get none")
other = sh(OPT, src, "--mg-set-fastmath=flags=reassoc,nsz").stdout; bad = sh(OPT, src, "--mg-set-fastmath=flags=reassoc,bogus")
report("fastmath<reassoc,nsz>" in other and "contract" not in other and bad.returncode != 0 and "unknown fast-math flag 'bogus'" in bad.stderr, "flags=reassoc,nsz gives exactly those flags; an unknown flag is an error with a message")
# ---- 2
print("-- 2. the driver")
def lowered(*flags):
    d = tempfile.mkdtemp(dir=W); sh(MGC, "build", os.path.join(root, "part29", "code", "examples", "08_self_attention_block.mg"), "-o", d + "/x", "-O0", "--no-outline", *flags, env=dict(env, MGC_KEEP=d))
    text = open(d + "/08_self_attention_block.ll").read(); return [l for l in text.split("\n") if re.search(r"= f(add|sub|mul|div) ", l)]
a, b, c = lowered(), lowered("--fast-math"), lowered("--fast-math=reassoc")
report(len(a) > 5 and all(" reassoc" not in l and " contract" not in l for l in a), f"default: {len(a)} fadd/fsub/fmul/fdiv in the self-attention example, none with a flag")
report(len(b) == len(a) and all(" reassoc contract " in l for l in b), "--fast-math: all %d carry reassoc contract" % len(b))
report(len(c) == len(a) and all(" reassoc " in l and " contract" not in l for l in c), "--fast-math=reassoc: all %d carry reassoc and nothing else" % len(c))
# ---- 3
print("-- 3. the loop vectorizer")
def verdict(example, fm):
    d = tempfile.mkdtemp(dir=W); sh(MGC, "lib", os.path.join(here, "examples", example), "-o", d, "-O0", "--no-outline", *(["--fast-math"] if fm else []), env=dict(env, MGC_KEEP=d))
    ll = [f for f in os.listdir(d) if f.endswith(".ll")][0]
    r = sh("clang-18", "-O3", f"-march={CPU}", "-Rpass=loop-vectorize", "-Rpass-missed=loop-vectorize", "-Rpass-analysis=loop-vectorize", "-c", d + "/" + ll, "-o", "/dev/null").stderr
    return ("vectorized loop" in r, "cannot prove it is safe to reorder floating-point operations" in r)
v = {(e, fm): verdict(e, fm) for e in ("02_matmul64.mg", "03_matmul_dynamic.mg") for fm in (False, True)}
report(all(v[(e, False)] == (False, True) and v[(e, True)][0] for e in ("02_matmul64.mg", "03_matmul_dynamic.mg")), "ijk product, static and dynamic sizes: not vectorized (cannot reorder floating-point operations) without the flags, vectorized with them", str(v))
# ---- 4
print("-- 4. the default prints the same on the book's examples")
def numbers(t): return [float(x) if x.lower() not in ("nan", "-nan") else math.nan for x in re.findall(r"-?(?:\d+\.?\d*(?:e[+-]?\d+)?|inf|nan)", re.sub(r"base@ = 0x[0-9a-f]+", "", t), re.I)]
def same(x, y):
    if len(x) != len(y): return False
    for u, w in zip(x, y):
        if math.isnan(u) or math.isnan(w):
            if not (math.isnan(u) and math.isnan(w)): return False
        elif math.isinf(u) or math.isinf(w):
            if u != w: return False
        elif abs(u - w) > 1e-5 * max(1.0, abs(w)): return False
    return True
progs = [f for f in sorted(glob.glob(root + "/part*/code/examples/*.mg") + glob.glob(root + "/tour/code/*.mg")) if sum(1 for _ in open(f)) < 400]
progs = [f for f in progs if sh(sys.executable, os.path.join(here, "mgfront.py"), f).returncode == 0]; progs = progs[::6]
ok = bad = 0; names = []
for f in progs:
    x = sh(MGC, "run", f, "-O2", env=env); y = sh(MGC, "run", f, "-O2", "--fast-math", env=env)
    if x.returncode == y.returncode and same(numbers(x.stdout), numbers(y.stdout)): ok += 1
    else: bad += 1; names.append(os.path.relpath(f, root))
report(bad == 0 and ok >= 15, f"{ok} programs (every sixth example) print the same at -O2 with --fast-math, {bad} differ", ", ".join(names))
# ---- 5
print("-- 5. the negative control: nnan changes an answer")
nan = os.path.join(here, "examples", "01_nan_compare.mg")
r = {fl: sh(MGC, "run", nan, "-O2", *fl, env=env).stdout.strip().split("\n")[-1].replace(" ", "") for fl in ((), ("--fast-math",), ("--fast-math=reassoc,contract,nnan",))}
report(list(r.values()) == ["[[0,0,0]]", "[[0,0,0]]", "[[1,1,1]]"], "ge(p, p) for a NaN p at -O2: plain %s, reassoc+contract %s, with nnan %s (the last is WRONG, and is why nnan is not a default)" % tuple(r.values()), str(r))
print("all checks pass" if not failures else f"{failures} CHECK(S) FAILED"); sys.exit(1 if failures else 0)
