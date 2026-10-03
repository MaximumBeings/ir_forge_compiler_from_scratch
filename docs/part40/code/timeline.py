#!/usr/bin/env python3
"""Chapter 40: a text picture of what the three engines do, cycle by cycle, for a small matrix product (32 x 32 x 32: 4 x 4 x 4 tiles) scheduled as one block of 2 x 2 tiles of C,
single buffered and double buffered. Each row is an engine; each character is TICK cycles; D = DMA transfer, M = matrix-unit product, v = vector-unit instruction, . = idle.
Output: timeline_out.txt"""
from ga import Machine, Sim
import schedules as S
m = Machine(slots=16); TICK = 4
def picture(db):
    A, B = S.matrices(32, 32, 32); sim, C = S.run(S.blocked(32, 32, 32, m, 2, 2, db), A, B, m); assert C == S.reference(A, B)
    rows = {e: ["."] * (sim.cycles // TICK + 1) for e in ("dma", "mxu", "vpu")}; ch = {"dma": "D", "mxu": "M", "vpu": "v"}
    for idx, eng, start, finish, rd, wr, fill in sim.trace:
        for t in range(start // TICK, max(start // TICK + 1, finish // TICK)): rows[eng][t] = ch[eng]
    print(f"2 x 2 block of C, {'double' if db else 'single'} buffered: {sim.cycles} cycles, {sim.dma_tiles} tiles moved, matrix-unit utilization {sim.report()['mxu_utilization']:.0%}   (one character = {TICK} cycles)")
    width = 120
    for e in ("dma", "mxu"):
        s = "".join(rows[e]); print(f"  {e:>3} " + s[:width] + (" ..." if len(s) > width else ""))
    print()
picture(False); picture(True)
