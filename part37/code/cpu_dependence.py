#!/usr/bin/env python3
"""Chapter 37: does what LLVM does with these loops depend on the CPU it compiles for? Compiles the same IR for four x86-64 CPUs (compilation only: nothing is run, so any
machine can do this) and reports, per CPU: the vectorizer's decision for ijk, ikj and ijk with the reassoc flag; the vgather instructions in the reassoc ijk loop and in
row_sum; the vector multiplies left in ijk after the whole -O3 pipeline; the fused multiply-adds with the contract flag; and llvm-mca's cycles per multiply-add.
Output: cpu_dependence_out.txt"""
import os, re, subprocess, sys, tempfile
here = os.path.dirname(os.path.abspath(__file__)); mgc = os.path.join(here, "..", "..", "part32", "code", "mgc"); work = tempfile.mkdtemp(prefix="ch37cpu_")
_newest = [os.path.join(here, "..", "..", p, "code", "build", "mg-opt") for p in ("part42", "part38", "part32")]      # the newest compiler build that exists (CI builds only Chapter 42's)
os.environ.setdefault("MG_OPT", next((p for p in _newest if os.path.exists(p)), _newest[-1]))
def sh(c, **k): return subprocess.run(c, capture_output=True, text=True, **k)
def build(src, name, order="ijk"):
    d = os.path.join(work, name); os.makedirs(d, exist_ok=True); sh([mgc, "lib", os.path.join(here, src), "-o", d, "-O0", "--matmul-order", order], env=dict(os.environ, MGC_KEEP=d)); return os.path.join(d, os.path.basename(src)[:-3] + ".ll")
ijk, ikj, rs = build("examples/02_matmul64.mg", "ijk"), build("examples/02_matmul64.mg", "ikj", "ikj"), build("ops/row_sum.mg", "rs")
reassoc = os.path.join(work, "re.ll"); open(reassoc, "w").write(open(ijk).read().replace("fadd double", "fadd reassoc double"))
contract = os.path.join(work, "ct.ll"); open(contract, "w").write(open(ikj).read().replace("fadd double", "fadd contract double").replace("fmul double", "fmul contract double"))
R = ["-Rpass=loop-vectorize", "-Rpass-missed=loop-vectorize", "-Rpass-analysis=loop-vectorize"]
def verdict(ll, cpu):
    e = sh(["clang-18", "-O3", f"-march={cpu}", *R, "-c", ll, "-o", "/dev/null"]).stderr
    m = re.search(r"vectorized loop \(vectorization width: (\d+), interleaved count: (\d+)\)", e)
    return f"vectorized (width {m.group(1)})" if m else "not vectorized"
def asm(ll, cpu): return sh(["clang-18", "-O3", f"-march={cpu}", "-S", ll, "-o", "-"]).stdout
rows = [("ijk", lambda c: verdict(ijk, c)), ("ikj", lambda c: verdict(ikj, c)), ("ijk + reassoc", lambda c: verdict(reassoc, c)),
        ("vgather in ijk + reassoc", lambda c: str(len(re.findall(r"\bvgather", asm(reassoc, c))))), ("vgather in row_sum", lambda c: str(len(re.findall(r"\bvgather", asm(rs, c))))),
        ("vector fmul left in ijk after -O3", lambda c: str(len(re.findall(r"fmul <", sh(["opt-18", "-mtriple=x86_64-unknown-linux-gnu", f"-mcpu={c}", "-passes=default<O3>", "-S", ijk]).stdout)))),
        ("vfmadd in ikj + contract", lambda c: str(len(re.findall(r"vfmadd", asm(contract, c))))),
        ("mca cycles/mul-add: ijk, ijk+reassoc, ikj", lambda c: " , ".join(l.split()[-1] for l in sh([sys.executable, os.path.join(here, "mca.py")], env=dict(os.environ, MCA_CPU=c)).stdout.strip().split("\n")[2:5]))]
cpus = ["sapphirerapids", "skylake-avx512", "haswell", "znver3"]
print("same IR, compiled for four x86-64 CPUs (compile only; clang -O3 -march=CPU, opt -mcpu=CPU, llvm-mca -mcpu=CPU)")
print(f"{'':<46}" + "".join(f"{c:<24}" for c in cpus))
for label, f in rows: print(f"{label:<46}" + "".join(f"{f(c):<24}" for c in cpus))
