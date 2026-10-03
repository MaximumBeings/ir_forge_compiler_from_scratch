#!/usr/bin/env python3
"""Chapter 37: ask llvm-mca (LLVM's machine-code analyzer, a model of how the CPU's pipeline runs a block of instructions) how many cycles the matrix product's inner loop
should take, for each variant: find the hot loop in the assembly (the innermost loop with the most multiply-adds per iteration), run it through llvm-mca-18 for this machine's CPU, and divide
by the number of multiply-adds in one iteration. llvm-mca assumes every load hits the L1 cache and every branch is predicted: it models the core, NOT the memory system.
Usage: mca.py [--loops]   Output: mca_out.txt (with --loops: loops_out.txt, the assembly of the ijk and ikj hot loops)"""
import os, re, subprocess, sys, tempfile
here = os.path.dirname(os.path.abspath(__file__)); mgc = os.path.join(here, "..", "..", "part32", "code", "mgc")
_newest = [os.path.join(here, "..", "..", p, "code", "build", "mg-opt") for p in ("part44", "part42", "part38", "part32")]      # the newest compiler build that exists (CI builds only Chapter 44's)
os.environ.setdefault("MG_OPT", next((p for p in _newest if os.path.exists(p)), _newest[-1]))
CPU = os.environ.get("MCA_CPU", "sapphirerapids")      # pinned: the result must not depend on the machine running the script
work = os.path.join(here, "work", "mca"); os.makedirs(work, exist_ok=True)
SRC = os.path.join(here, "examples", "03_matmul_dynamic.mg")
def build(name, order, edit):
    d = os.path.join(work, name); os.makedirs(d, exist_ok=True)
    subprocess.run([mgc, "lib", SRC, "-o", d, "-O0", "--matmul-order", order], check=True, capture_output=True, env=dict(os.environ, MGC_KEEP=d))
    ll = os.path.join(d, "03_matmul_dynamic.ll"); text = open(ll).read()
    for a, b in edit: text = text.replace(a, b)
    open(ll, "w").write(text)
    s = os.path.join(d, "mm.s"); subprocess.run(["clang-18", "-O3", f"-march={CPU}", "-S", ll, "-o", s], check=True, capture_output=True)
    return s
def lanes(x): return 8 if "zmm" in x else 4 if "ymm" in x else 2 if re.search(r"pd\b", x) and "xmm" in x else 1
def hot_loop(path):
    lines = open(path).read().split("\n"); loops = []
    for i, l in enumerate(lines):
        m = re.match(r"^(\.LBB\d+_\d+):", l)
        if not m: continue
        lab = m.group(1); end = None
        for j in range(i + 1, len(lines)):
            if re.match(r"^\s+j\w+\s+" + re.escape(lab) + r"\s*$", lines[j]): end = j
        if end is not None: loops.append((i, end))
    inner = [(i, e) for i, e in loops if not any(i < i2 and e2 <= e for i2, e2 in loops)]       # innermost loops only: no other loop inside
    best = None
    for i, e in inner:
        body = [x for x in lines[i + 1:e + 1] if x.startswith("\t") and not x.strip().startswith(("#", "."))]
        mults = sum(lanes(x) for x in body if re.search(r"\bv(mul|fmadd)", x))        # multiply-adds per iteration, counting every lane of a vector instruction
        if best is None or mults > best[0]: best = (mults, body)
    return best[1]
def analyse(name, order, edit=()):
    body = hot_loop(build(name, order, edit)); macs = sum(lanes(x) for x in body if re.search(r"\bv(mul|fmadd)", x))
    asm = "# LLVM-MCA-BEGIN\n" + "\n".join(body) + "\n# LLVM-MCA-END\n"
    with tempfile.NamedTemporaryFile("w", suffix=".s", delete=False) as f: f.write(asm); p = f.name
    out = subprocess.run(["llvm-mca-18", f"-mcpu={CPU}", "-iterations=100", p], capture_output=True, text=True).stdout; os.unlink(p)
    cyc = int(re.search(r"Total Cycles:\s+(\d+)", out).group(1)); thr = float(re.search(r"Block RThroughput:\s+([\d.]+)", out).group(1))
    return len(body), macs, cyc / 100, thr
def main():
    rows = [("ijk (the default order)", "ijk", ()), ("ijk, reassoc on every fadd", "ijk", [("fadd double", "fadd reassoc double")]),
            ("ikj", "ikj", ()), ("ikj, contract on every fmul and fadd", "ikj", [("fadd double", "fadd contract double"), ("fmul double", "fmul contract double")])]
    print(f"llvm-mca-18, -mcpu={CPU}, 100 iterations of the loop body; dynamic sizes (examples/03_matmul_dynamic.mg), clang -O3 -march={CPU}")
    print(f"{'variant':<42} {'instrs':>6} {'mul-adds':>8} {'cycles/iter':>11} {'cycles per mul-add':>19}")
    if "--loops" in sys.argv:          # print the hot loop of each variant instead of analysing it
        for label, order, edit in rows[:3:2]:
            body = hot_loop(build(label.split(",")[0].replace(" ", "_") + str(len(edit)), order, edit)); print(f"## {label}: the innermost loop with the most multiply-adds ({len(body)} instructions)"); print("\n".join(x.split("#")[0].rstrip() for x in body)); print()
        return
    for label, order, edit in rows:
        n, macs, cyc, thr = analyse(label.split(",")[0].replace(" ", "_") + str(len(edit)), order, edit)
        print(f"{label:<42} {n:>6} {macs:>8} {cyc:>11.1f} {cyc / macs:>19.2f}")
if __name__ == "__main__": main()
