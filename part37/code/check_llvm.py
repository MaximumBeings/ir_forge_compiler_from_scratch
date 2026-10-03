#!/usr/bin/env python3
"""Checks the Chapter 37 claims about what LLVM does with Mountain Goat's loops, by running the tools and testing the facts the page states:

  1. THE IR: the small program's LLVM IR has the expected shape (one fadd, one malloc, a loop nest of phi nodes); the matrix product's has a fmul and a fadd in its inner loop;
  2. THE PASSES (opt): after the loop vectorizer the ikj order has vector arithmetic and the ijk order has only the zero-fill store; the whole -O3 pipeline turns ijk's
     malloc and zero-fill loop into one calloc and keeps the accumulator in a register (a phi of a double), and leaves no vector multiply;
  3. THE VECTORIZER'S REASONS (clang remarks): ijk is not vectorized "because it cannot prove it is safe to reorder floating-point operations"; ikj is vectorized; ijk with
     the reassoc flag in the IR is vectorized, and gathers the column of b with vgather instructions where ikj has none; clang's -ffast-math option leaves the assembly byte for byte unchanged;
  4. THE OPERATIONS: add has packed arithmetic and no scalar; exp has a call to exp and no packed arithmetic; row_sum uses gathers; transpose has no packed arithmetic;
  5. THE BACKEND: the ikj assembly has no fused multiply-add, and the same IR with the contract flag has some; llvm-mca predicts ijk costs more than 5x ikj per multiply-add,
     and ijk with reassoc less than a third of ijk.
The target CPU is pinned (sapphirerapids; CHK_CPU changes it): the vectorizer's choices depend on the CPU (see cpu_dependence.py), so the claims are claims about that target.
Environment variables (CHK_*) change how an input is built; model_mutation.sh sets them to check that each check can fail. Defaults give the page's experiments.
Usage: check_llvm.py      Exit status 0 only if every check passes."""
import os, re, subprocess, sys, tempfile
here = os.path.dirname(os.path.abspath(__file__)); mgc = os.path.join(here, "..", "..", "part32", "code", "mgc")
_newest = [os.path.join(here, "..", "..", p, "code", "build", "mg-opt") for p in ("part42", "part38", "part32")]      # the newest compiler build that exists (CI builds only Chapter 42's)
os.environ.setdefault("MG_OPT", next((p for p in _newest if os.path.exists(p)), _newest[-1]))
work = tempfile.mkdtemp(prefix="ch37_")
E = os.environ.get
CPU = E("CHK_CPU", "sapphirerapids")          # pinned, so the expected values do not depend on the machine running the check (CI ran on a different CPU and got different assembly)
ORDER_IJK, MARCH = E("CHK_ORDER_IJK", "ijk"), E("CHK_MARCH", f"-march={CPU}")
REASSOC, CONTRACT, FASTFLAG = E("CHK_REASSOC", "fadd reassoc double"), E("CHK_CONTRACT", "contract"), E("CHK_FAST_FLAG", "-ffast-math")
TRIPLE = E("CHK_TRIPLE", f"-mtriple=x86_64-unknown-linux-gnu -mcpu={CPU}").split()
failures = 0
def report(ok, name, detail=""):
    global failures; failures += not ok
    print(f"  {'ok  ' if ok else 'FAIL'} {name}" + ("" if ok else f"\n       {detail}"))
def sh(cmd, **kw): return subprocess.run(cmd, capture_output=True, text=True, **kw)
def build(src, name, order="ijk", *extra):
    d = os.path.join(work, name); os.makedirs(d, exist_ok=True)
    r = sh([mgc, "lib", os.path.join(here, src), "-o", d, "-O0", "--matmul-order", order, *extra], env=dict(os.environ, MGC_KEEP=d))
    if r.returncode: raise RuntimeError(r.stderr)
    return os.path.join(d, os.path.basename(src)[:-3] + ".ll")
def opt(ll, pipe): return sh(["opt-18", *TRIPLE, f"-passes={pipe}", "-S", ll]).stdout
def clang(ll, *flags, out="/dev/null"): return sh(["clang-18", "-O3", *flags, *( ["-S"] if out.endswith(".s") else ["-c"] ), ll, "-o", out])
def remarks(ll, *flags): return clang(ll, *flags, "-Rpass=loop-vectorize", "-Rpass-missed=loop-vectorize", "-Rpass-analysis=loop-vectorize").stderr
def asm(ll, name, *flags):
    p = os.path.join(work, name + ".s"); clang(ll, *flags, out=p); return open(p).read()
PACKED = r"\bv(add|mul|sub|div|max|min|sqrt|cmp)[a-z]*pd\b"; SCALAR = r"\bv(add|mul|sub|div|max|min|sqrt|cmp)[a-z]*sd\b"
P4 = "function(instcombine,simplifycfg,loop-simplify,lcssa,loop-rotate,loop-mssa(licm),indvars,loop-vectorize)"

print("-- 1. reading the IR")
add = open(build("examples/01_add2x2.mg", "add2")).read()
report(add.count("fadd double") == 1 and add.count("call ptr @malloc") == 1 and add.count("phi i64") == 2, "the 2x2 add: one fadd, one malloc, two loop counters (phi i64)", f"{add.count('fadd double')} fadd, {add.count('@malloc')} malloc, {add.count('phi i64')} phi")
ijk = build("examples/02_matmul64.mg", "ijk", ORDER_IJK); ikj = build("examples/02_matmul64.mg", "ikj", "ikj")
t = open(ijk).read()
report("fmul double" in t and "fadd double" in t and t.count("phi i64") == 5, "the 64x64 product (ijk): a fmul and a fadd, five loop counters (two for the zero fill, three for the product)", f"{t.count('phi i64')} phi i64")
print("-- 2. the passes (opt)")
v = lambda ll, pipe: len(re.findall(r"<\d+ x double>", opt(ll, pipe)))
vi, vk = opt(ijk, P4), opt(ikj, P4)
report(len(re.findall(r"fmul <\d+ x double>", vk)) > 0, "after loop-vectorize the ikj order has a vector fmul", str(len(re.findall(r"<\d+ x double>", vk))))
report(len(re.findall(r"fmul <\d+ x double>", vi)) == 0 and re.search(r"store <\d+ x double> zeroinitializer", vi) is not None, "after loop-vectorize the ijk order has no vector fmul, only the vector store of zeros", str(re.findall(r"<\d+ x double>", vi)[:3]))
o3 = opt(ijk, "default<O3>")
report("@calloc" in o3 and "@malloc" not in o3, "the whole -O3 pipeline turns ijk's malloc and zero-fill loop into one calloc", f"calloc={o3.count('@calloc')} malloc={o3.count('@malloc')}")
report(re.search(r"phi double \[ %\.promoted", o3) is not None and len(re.findall(r"fmul <", o3)) == 0, "the accumulator lives in a register (phi double, promoted from memory) and no multiply is a vector one", "")
print("-- 3. the vectorizer's reasons (clang remarks)")
report("cannot prove it is safe to reorder floating-point operations" in remarks(ijk, MARCH), "ijk: not vectorized, 'cannot prove it is safe to reorder floating-point operations'", remarks(ijk, MARCH)[:300])
report("vectorized loop" in remarks(ikj, MARCH), "ikj: 'vectorized loop'", remarks(ikj, MARCH)[:300])
re_ll = os.path.join(work, "ijk_reassoc.ll"); open(re_ll, "w").write(open(ijk).read().replace("fadd double", REASSOC))
report("vectorized loop" in remarks(re_ll, MARCH), "ijk with the reassoc flag on its fadd: 'vectorized loop'", remarks(re_ll, MARCH)[:300])
g_re, g_ikj = len(re.findall(r"\bvgather", asm(re_ll, "reassoc", MARCH))), len(re.findall(r"\bvgather", asm(ikj, "ikj_g", MARCH)))
report(g_re > 0 and g_ikj == 0, f"the vectorized ijk gathers the column of b with vgather instructions ({g_re}); ikj needs none ({g_ikj})", f"{g_re} vs {g_ikj}")
report(asm(ijk, "plain", MARCH) == asm(ijk, "fast", MARCH, FASTFLAG), f"clang's {FASTFLAG} on the unchanged .ll leaves the assembly byte for byte identical", "the assembly differs")
print("-- 4. the operations (packed = vector arithmetic, scalar = one double at a time)")
def op(name):
    ll = build(f"ops/{name}.mg", name); s = asm(ll, name, MARCH)
    return len(re.findall(PACKED, s)), len(re.findall(SCALAR, s)), len(re.findall(r"\bvgather", s)), sorted(set(x for x in re.findall(r"call[q]?\s+(\w+)@PLT", s) if x not in ("malloc", "calloc", "free")))
a = op("add"); report(a[0] > 0 and a[1] == 0, f"add: packed arithmetic ({a[0]}), no scalar arithmetic ({a[1]})", str(a))
e = op("exp"); report(e[0] == 0 and "exp" in e[3], f"exp: no packed arithmetic, a library call to {e[3]}", str(e))
rs = op("row_sum"); report(rs[0] > 0 and rs[2] > 0, f"row_sum: packed arithmetic ({rs[0]}) fed by gathers ({rs[2]})", str(rs))
tr = op("transpose"); report(tr[0] == 0, f"transpose: no arithmetic at all ({tr[0]} packed), only moves", str(tr))
print("-- 5. the backend")
fm_plain = len(re.findall(r"vfmadd", asm(ikj, "ikj_plain", MARCH)))
ct = os.path.join(work, "ikj_contract.ll"); open(ct, "w").write(open(ikj).read().replace("fadd double", f"fadd {CONTRACT} double").replace("fmul double", f"fmul {CONTRACT} double"))
fm_ct = len(re.findall(r"vfmadd", asm(ct, "ikj_ct", MARCH)))
report(fm_plain == 0 and fm_ct > 0, f"ikj: no fused multiply-add ({fm_plain}); with the contract flag: {fm_ct}", f"{fm_plain} vs {fm_ct}")
m = sh([sys.executable, os.path.join(here, "mca.py")], env=dict(os.environ, MCA_CPU=CPU)).stdout.strip().split("\n")
cyc = {l.split("  ")[0].strip(): float(l.split()[-1]) for l in m[2:] if l.strip()}
k = list(cyc.values()); report(len(k) == 4 and k[0] > 5 * k[2], f"llvm-mca: ijk {k[0]} cycles per multiply-add against ikj {k[2]} (more than 5x)", str(m))
report(len(k) == 4 and k[1] < k[0] / 3, f"llvm-mca: ijk with reassoc {k[1]} against ijk {k[0]} (less than a third)", str(m))
print("all checks pass" if failures == 0 else f"{failures} CHECK(S) FAILED")
sys.exit(1 if failures else 0)
