#!/usr/bin/env python3
"""Chapter 40: how much does the schedule matter as the memory gets faster? The same 128 x 128 x 128 product on GA-1 machines whose DMA moves 8, 16, 32 or 64 words per cycle once
started (setup cost 16 cycles each transfer, or 4), for three double-buffered schedules: 1x1 (the plain loop order), 2x4 and 4x8 blocks. Output: bandwidth_sweep_out.txt"""
from ga import Machine
import schedules as S
A, B = S.matrices(128, 128, 128); want = S.reference(A, B)
print("128 x 128 x 128, double buffered, 64 tile slots; cycles (matrix-unit utilization); the matrix unit alone needs 32768 cycles")
print(f"{'DMA words/cycle, setup':<24} {'tile cycles':>11} {'1x1':>18} {'2x4':>18} {'4x8':>18}   {'1x1 / 4x8':>9}")
for setup in (16, 4):
    for bw in (8, 16, 32, 64):
        m = Machine(slots=64, dma_words_per_cycle=bw, dma_setup=setup); cells = []; cyc = []
        for bi, bj in ((1, 1), (2, 4), (4, 8)):
            sim, C = S.run(S.blocked(128, 128, 128, m, bi, bj, True), A, B, m); assert C == want; r = sim.report(); cells.append(f"{r['cycles']:>8} ({r['mxu_utilization']:.0%})"); cyc.append(r["cycles"])
        print(f"{bw:>8} words, setup {setup:<3}    {m.dma_cycles:>11} " + " ".join(f"{c:>18}" for c in cells) + f"   {cyc[0] / cyc[2]:>8.2f}x")
