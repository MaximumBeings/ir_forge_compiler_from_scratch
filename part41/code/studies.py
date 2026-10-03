#!/usr/bin/env python3
"""Chapter 41: three studies with the GA-1 back end.
 1. OPTIONS: what do common-subexpression elimination, fusion and double buffering each buy, on programs from earlier chapters?
 2. DECODE AND PREFILL: the same feed-forward network (width 64 -> 256 -> 64) for 1, 2, 4 ... 64 tokens at once: cycles, cycles per token, useful utilization of the matrix unit,
    and how busy the DMA is. (Generating one token at a time is "decode"; processing a whole prompt at once is "prefill".)
 3. A BLOCK: where do the cycles of one transformer block (64 tokens, width 64) go, kernel by kernel?
Each program is also run on the CPU path (mgc run) and compared, so every number below is for a program that computed the right answer.   Output: studies_out.txt"""
import os, subprocess, sys
here = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, here)
import ga_backend as B, make_block as MB
from compare_with_cpu import cpu_matrices, close, MGC
from ga import Machine
work = os.path.join(here, "work"); os.makedirs(work, exist_ok=True)
def mlir_of(path): return subprocess.run([MGC, "mlir", path], capture_output=True, text=True, check=True).stdout
def put(name, text): p = os.path.join(work, name); open(p, "w").write(text); return p
def go(path, machine, **opts):
    c = B.compile_text(mlir_of(path), machine, **opts); sim, outs = B.run_compiled(c, machine); ok = close(outs, cpu_matrices(path)); assert ok, path; return c, sim
print("STUDY 1. compiler options (32 tile slots). cycles for each combination; every program matches the CPU result")
progs = [("part29 04_softmax_stable", os.path.join(here, "..", "..", "part29", "code", "examples", "04_softmax_stable.mg")), ("part29 08_self_attention_block", os.path.join(here, "..", "..", "part29", "code", "examples", "08_self_attention_block.mg")),
         ("part30 03_tiny_transformer", os.path.join(here, "..", "..", "part30", "code", "examples", "03_tiny_transformer.mg")), ("block 8 tokens x 16", put("block_8_16.mg", MB.block(8, 16, 32))), ("block 32 tokens x 32", put("block_32_32.mg", MB.block(32, 32, 64)))]
m = Machine(slots=32)
combos = [("nothing", dict(cse_on=False, fuse=False, double_buffer=False)), ("+ cse", dict(cse_on=True, fuse=False, double_buffer=False)), ("+ cse + fusion", dict(cse_on=True, fuse=True, double_buffer=False)),
          ("+ cse + double buffering", dict(cse_on=True, fuse=False, double_buffer=True)), ("all three", dict(cse_on=True, fuse=True, double_buffer=True))]
print(f"{'program':<34}" + "".join(f"{n:>26}" for n, _ in combos))
for name, path in progs:
    row = []
    for _, opts in combos: c, sim = go(path, m, **opts); row.append(sim.cycles)
    print(f"{name:<34}" + "".join(f"{x:>14} ({row[0] / x:.2f}x)  " if k else f"{x:>14}            " for k, x in enumerate(row)))
print("\nSTUDY 2. one feed-forward network, relu(x @ w1 + b1) @ w2 + b2, width 64 -> 256 -> 64, for T tokens at once (64 tile slots, all options on)")
m = Machine(slots=64)
print(f"{'tokens':>6} {'cycles':>9} {'cycles/token':>13} {'useful MXU':>11} {'DMA busy':>9} {'DMA tiles moved':>16}")
for t in (1, 2, 4, 8, 16, 32, 64):
    c, sim = go(put(f"ffn_{t}.mg", MB.ffn_only(t, 64, 256)), m); r = sim.report()
    print(f"{t:>6} {sim.cycles:>9} {sim.cycles / t:>13.0f} {sim.useful_utilization:>10.1%} {r['dma_busy']:>9.0%} {r['dma_tiles']:>16}")
print("\nSTUDY 3. one transformer block, 64 tokens, width 64, feed-forward 128 (32 tile slots, all options on): the kernels, in program order")
m = Machine(slots=32); c, sim = go(put("block_64_64.mg", MB.block(64, 64, 128)), m); rows = B.kernel_table(c, sim)
print(f"total {sim.cycles} cycles; useful MXU utilization {sim.useful_utilization:.0%}; DMA busy {sim.report()['dma_busy']:.0%}, MXU busy {sim.report()['mxu_busy']:.0%}, VPU busy {sim.report()['vpu_busy']:.0%}")
agg = {}
for r in rows:
    k = r["kind"].split(" ")[0] if r["kind"].startswith("elementwise") else r["kind"]; a = agg.setdefault(k, dict(n=0, dma=0, mxu=0, vpu=0, span=0)); a["n"] += 1; a["dma"] += r["dma"]; a["mxu"] += r["mxu"]; a["vpu"] += r["vpu"]; a["span"] += r["span"]
print(f"{'kernel kind':<14} {'count':>5} {'DMA busy':>9} {'MXU busy':>9} {'VPU busy':>9} {'sum of spans':>13}")
for k, a in sorted(agg.items(), key=lambda kv: -kv[1]["span"]): print(f"{k:<14} {a['n']:>5} {a['dma']:>9} {a['mxu']:>9} {a['vpu']:>9} {a['span']:>13}")
