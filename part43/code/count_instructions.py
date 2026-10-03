#!/usr/bin/env python3
"""Chapter 43: the run-time cost of outlining in EXACT instructions (valgrind --tool=callgrind counts every instruction the executable runs; unlike wall time it does not vary between runs).
Chapter 35's and Chapter 36's 10-step training programs, loops lowered last to first, with and without --outline, at clang -O0 and -O2 (Chapter 36's at -O2 takes several minutes to compile
without outlining, so only Chapter 35's is built at -O2; the 200-step program only at -O0). Reports instructions executed, the static number of calls to outlined functions (main is straight-line, so each runs once),
and the extra instructions per call. Output: count_instructions_out.txt   (about 15 minutes)"""
import os, re, subprocess, sys, tempfile
here = os.path.dirname(os.path.abspath(__file__)); ROOT = os.path.join(here, "..", ".."); MGC = os.path.join(ROOT, "part42", "code", "mgc"); W = tempfile.mkdtemp(prefix="ch43i_")
CASES = [("ch35 10 steps", "part35/code/examples/03_train_10_steps.mg", ("-O0", "-O2")), ("ch36 10 steps", "part36/code/examples/03_train_10_steps.mg", ("-O0",)), ("ch36 200 steps", "part36/code/examples/04_train_200_steps.mg", ("-O0",))]
def build(prog, opt, outline):
    tag = f"{prog.split('/')[0]}.{os.path.basename(prog)}.{opt}.{'out' if outline else 'plain'}"; keep = f"{W}/{tag}.d"; os.makedirs(keep)
    env = dict(os.environ, MGC_KEEP=keep)
    subprocess.run([MGC, "build", os.path.join(ROOT, prog), "-o", f"{W}/{tag}", opt, "--reverse-loops"] + (["--outline"] if outline else []), capture_output=True, check=True, env=env)
    ll = open(os.path.join(keep, os.path.basename(prog)[:-3] + ".ll")).read()
    return f"{W}/{tag}", len(re.findall(r"call void @mg_outlined", ll))
def instructions(exe):
    cg = exe + ".cg"; subprocess.run(["valgrind", "--tool=callgrind", f"--callgrind-out-file={cg}", exe], capture_output=True)
    m = re.search(r"summary: (\d+)", open(cg).read()); return int(m.group(1))
print(f"{'program':16} {'clang':>5} {'plain instructions':>20} {'outlined instructions':>22} {'extra':>12} {'ratio':>7} {'calls':>7} {'extra per call':>15}")
for name, prog, opts in CASES:
    for opt in opts:
        a, _ = build(prog, opt, False); b, calls = build(prog, opt, True); ia, ib = instructions(a), instructions(b)
        print(f"{name:16} {opt:>5} {ia:>20,} {ib:>22,} {ib - ia:>12,} {ib / ia:>7.3f} {calls:>7,} {(ib - ia) / max(calls, 1):>15.1f}", flush=True)
