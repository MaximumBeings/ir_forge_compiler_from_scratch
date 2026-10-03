#!/usr/bin/env python3
"""Checks the Chapter 41 back end.

  1. AGREEMENT WITH THE CPU: every example of Chapters 20-32 and the tour that the back end accepts gives the same printed matrices as `mgc run` (61 programs; 0 may differ; 4 print nothing);
     the ones it rejects are rejected for the two stated reasons (dynamic shapes, rank other than 2);
  2. ALL OPTION COMBINATIONS: each of the 8 combinations of cse / fusion / double buffering gives the right answer on three programs;
  3. OTHER MACHINES: tiles of 4, 8 and 16 words and scratchpads of 24 and 64 slots give the right answer (so nothing depends on the tile size or on the padding being 8);
  4. WHAT THE OPTIONS DO (pinned cycle counts, GA-1's own numbers): softmax of the stable example 1854 -> 1194 (cse) -> 804 (cse + fusion); the 8-token block 7484 -> 3564 with all
     three options; fusion leaves exactly the kernels the stored values require; double buffering changes nothing for one-tile kernels and helps a block;
  5. DECODE AND PREFILL: the feed-forward network takes the same cycles for 1, 2, 4 and 8 tokens (14400: the weights are streamed once for all of them), so cycles per token fall 8x,
     and useful matrix-unit utilization is exactly proportional to the tokens (3.6% to 28.4%);
  6. UNSUPPORTED: dynamic shapes and rank 3 are refused with a message.
Usage: check_backend.py     Exit status 0 only if every check passes."""
import glob, os, subprocess, sys, tempfile
here = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, here)
import ga_backend as B, make_block as MB
import compare_with_cpu as CC
from compare_with_cpu import cpu_matrices, close, MGC, root
from ga import Machine
failures = 0
def report(ok, name, detail=""):
    global failures; failures += not ok
    print(f"  {'ok  ' if ok else 'FAIL'} {name}" + ("" if ok else f"\n       {detail}"))
work = tempfile.mkdtemp(prefix="ch41_")
def put(name, text): p = os.path.join(work, name); open(p, "w").write(text); return p
def mlir(path): return subprocess.run([MGC, "mlir", path], capture_output=True, text=True).stdout
def example(part, name): return os.path.join(root, part, "code", "examples", name)
def run(path, machine, **opts):
    c = B.compile_text(mlir(path), machine, **opts); sim, outs = B.run_compiled(c, machine); return c, sim, outs

print("-- 1. agreement with the CPU path on the book's examples")
files = sorted(f for f in glob.glob(os.path.join(root, "part2[0-9]", "code", "examples", "*.mg")) + glob.glob(os.path.join(root, "part3[0-2]", "code", "examples", "*.mg")) + glob.glob(os.path.join(root, "tour", "code", "*.mg")) if sum(1 for _ in open(f)) < 400)
rows = CC.main(files); status = [r[1] for r in rows]
report(status.count("DIFFERENT") == 0 and status.count("same") >= 60, f"{status.count('same')} programs print the same matrices as the CPU path, {status.count('DIFFERENT')} differ", str([r for r in rows if r[1] == "DIFFERENT"][:3]))
report(all(("dynamic shapes" in r[2] or "rank" in r[2]) for r in rows if r[1] == "unsupported"), f"the {status.count('unsupported')} rejected programs are rejected for dynamic shapes or rank, nothing else", str([r for r in rows if r[1] == "unsupported" and not ("dynamic" in r[2] or "rank" in r[2])][:3]))
print("-- 2. all option combinations")
progs = [example("part29", "04_softmax_stable.mg"), example("part30", "03_tiny_transformer.mg"), put("b.mg", MB.block(8, 16, 32))]
bad = []
for p in progs:
    want = cpu_matrices(p)
    for cse_on in (False, True):
        for fuse in (False, True):
            for db in (False, True):
                c, sim, outs = run(p, Machine(slots=32), cse_on=cse_on, fuse=fuse, double_buffer=db)
                if not close(outs, want): bad.append((os.path.basename(p), cse_on, fuse, db))
report(not bad, "all 8 combinations of cse / fusion / double buffering give the CPU's answer on 3 programs", str(bad[:3]))
print("-- 3. other machines")
want = cpu_matrices(progs[2]); bad = []
for T in (4, 8, 16):
    for slots in (24, 64):
        try: c, sim, outs = run(progs[2], Machine(T=T, slots=slots, mxu_cycles=T, mxu_fill=T))
        except B.Unsupported as e: bad.append((T, slots, str(e))); continue
        if not close(outs, want): bad.append((T, slots, "wrong answer"))
report(not bad, "tiles of 4, 8 and 16 and scratchpads of 24 and 64 slots all give the CPU's answer", str(bad))
print("-- 4. what the options do")
sm = example("part29", "04_softmax_stable.mg"); cyc = lambda p, **o: run(p, Machine(slots=32), **o)[1].cycles
a, b, c3 = cyc(sm, cse_on=False, fuse=False, double_buffer=False), cyc(sm, cse_on=True, fuse=False, double_buffer=False), cyc(sm, cse_on=True, fuse=True, double_buffer=False)
report((a, b, c3) == (1854, 1194, 804), f"softmax (stable): {a} cycles with nothing, {b} with cse, {c3} with cse and fusion", f"{(a, b, c3)}")
blk = progs[2]; n0 = cyc(blk, cse_on=False, fuse=False, double_buffer=False); n3 = cyc(blk, cse_on=True, fuse=True, double_buffer=True)
report((n0, n3) == (7484, 3564), f"8-token block: {n0} cycles with nothing, {n3} with all three options", f"{(n0, n3)}")
k_fused = [k["kind"] for k in run(sm, Machine(slots=32), cse_on=True, fuse=True, double_buffer=True)[0].kernels]; k_plain = [k["kind"] for k in run(sm, Machine(slots=32), cse_on=True, fuse=False, double_buffer=True)[0].kernels]
report(k_fused[:4] == ["reduce", "elementwise x3", "reduce", "elementwise x2"] and (len(k_plain), len(k_fused)) == (22, 13), f"fusion turns {len(k_plain)} kernels into {len(k_fused)}; each softmax becomes reduce, elementwise x3, reduce, elementwise x2", f"{k_fused} {len(k_plain)}")
report(cyc(sm, double_buffer=False) == cyc(sm, double_buffer=True) and cyc(blk, double_buffer=True) < cyc(blk, double_buffer=False), "double buffering changes nothing for one-tile kernels (softmax) and helps the block", "")
print("-- 5. decode and prefill")
res = {}
for t in (1, 2, 4, 8):
    p = put(f"f{t}.mg", MB.ffn_only(t, 64, 256)); c, sim, outs = run(p, Machine(slots=64)); res[t] = (sim.cycles, sim.useful_utilization)
    assert close(outs, cpu_matrices(p))
report(len({v[0] for v in res.values()}) == 1 and res[1][0] == 14400, f"1, 2, 4 and 8 tokens all take {res[1][0]} cycles (the weights are streamed once for all of them)", str(res))
report(all(abs(res[t][1] / res[1][1] - t) < 1e-9 for t in res), "useful matrix-unit utilization is proportional to the tokens: " + ", ".join(f"{t}: {v[1]:.1%}" for t, v in res.items()), str(res))
print("-- 6. unsupported programs")
msgs = []
for name, src in (("dyn.mg", "def f(a: tensor[?x?]) = a + a\nlet m = [[1, 2], [3, 4]]\nprint f(m)\n"), ("r3.mg", open(example("part28", "01_reshape_and_permute.mg")).read())):
    p = put(name, src); t = subprocess.run([MGC, "mlir", p], capture_output=True, text=True); assert t.returncode == 0 and "func.func @main" in t.stdout, (name, t.stderr[:200])
    try: B.compile_text(t.stdout, Machine()); msgs.append("accepted")
    except B.Unsupported as e: msgs.append(str(e))
report(all(("dynamic" in m or "rank" in m) for m in msgs), "dynamic shapes and rank 3 are refused with a message: " + "; ".join(m[:60] for m in msgs), str(msgs))
print("all checks pass" if failures == 0 else f"{failures} CHECK(S) FAILED"); sys.exit(1 if failures else 0)
