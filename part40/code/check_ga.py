#!/usr/bin/env python3
"""Checks the Chapter 40 simulator and schedules.

  1. RESULTS: every schedule (blocked with several block shapes, with and without double buffering, and k-outermost) gives exactly the plain triple loop's C, for shapes that
     are and are not multiples of the tile size (including a single row and a single column);
  2. TRAFFIC: the number of tiles moved equals the formula (blocked: per block, per k, bi + bj loads, plus one store per tile of C; k-outermost: 2 loads per product, a load of the
     partial C for every k after the first, and a store for every k);
  3. TIMING, from first principles: a six-instruction program whose cycle count is worked out by hand; the 4 x 4 double-buffered schedule is DMA-bound (cycles = tiles moved x
     cycles per tile, exactly); no schedule beats the matrix-unit bound or the DMA bound; more reuse never moves more tiles;
  4. HAZARDS, independently: the simulator records when every instruction started and finished; this check replays the trace and verifies, for every slot, that no instruction read
     a value before the write that produced it had finished (plus the fill time for a non-accumulating reader), and that no write began before the earlier reads of that slot ended.
Usage: check_ga.py     Exit status 0 only if every check passes."""
import itertools, sys, random
from ga import Machine, Sim
import schedules as S
failures = 0
def report(ok, name, detail=""):
    global failures; failures += not ok
    print(f"  {'ok  ' if ok else 'FAIL'} {name}" + ("" if ok else f"\n       {detail}"))
m = Machine(slots=64)

def hazards_general(sim):
    """The same idea, written the straightforward way: for each slot, the sequence of its uses in program order; every use must respect the previous ones."""
    bad = []; last_write = {}; reads_since = {}
    for idx, eng, start, finish, rd, wr, fill in sim.trace:
        accs = set(rd) & set(wr)                          # accumulating (read-modify-write) slots
        for s in rd:
            if s in last_write:
                wf, wfill, was_acc = last_write[s]
                need = wf if (s in accs and was_acc) else wf + wfill      # an accumulating read after an accumulating write needs no fill
                if start < need: bad.append((idx, "read too early", s, start, need))
        for s in wr:
            for rf in reads_since.get(s, []):
                if start < rf: bad.append((idx, "write too early", s, start, rf))
        for s in rd: reads_since.setdefault(s, []).append(finish)
        for s in wr:
            last_write[s] = (finish, fill, s in accs); reads_since[s] = [finish] if s in accs else []
    return bad

print("-- 1. results")
shapes = [(8, 8, 8), (24, 16, 32), (20, 13, 30), (1, 17, 9), (9, 17, 1), (40, 40, 40), (64, 64, 64)]
schedules = [("blocked 1x1", lambda M, K, N, db: S.blocked(M, K, N, m, 1, 1, db)), ("blocked 2x2", lambda M, K, N, db: S.blocked(M, K, N, m, 2, 2, db)),
             ("blocked 1x4", lambda M, K, N, db: S.blocked(M, K, N, m, 1, 4, db)), ("blocked 3x2", lambda M, K, N, db: S.blocked(M, K, N, m, 3, 2, db)),
             ("k outermost", lambda M, K, N, db: S.kouter(M, K, N, m, db))]
bad_results = []; bad_traffic = []; bad_haz = []; count = 0; sims = {}
for (M, K, N), (name, build), db in itertools.product(shapes, schedules, (False, True)):
    A, B = S.matrices(M, K, N, seed=M + K + N); prog = build(M, K, N, db); sim, C = S.run(prog, A, B, m); count += 1; sims[(M, K, N, name, db)] = sim
    if C != S.reference(A, B): bad_results.append((M, K, N, name, db))
    Mt, Kt, Nt = (-(-M // 8), -(-K // 8), -(-N // 8))
    if name.startswith("blocked"):
        bi, bj = map(int, name.split()[1].split("x")); loads, stores = S.expected_blocked_tiles(M, K, N, m, bi, bj)
    else: loads, stores = 2 * Mt * Nt * Kt + Mt * Nt * (Kt - 1), Mt * Nt * Kt
    if (sim.dma_loads, sim.dma_stores) != (loads, stores): bad_traffic.append((M, K, N, name, db, (sim.dma_loads, sim.dma_stores), (loads, stores)))
    hz = hazards_general(sim)
    if hz: bad_haz.append((M, K, N, name, db, hz[:2]))
report(not bad_results, f"all {count} schedule/shape/buffering combinations give exactly the triple loop's result", str(bad_results[:3]))
print("-- 2. traffic")
report(not bad_traffic, f"tiles loaded and stored equal the formula in all {count} runs", str(bad_traffic[:3]))
print("-- 3. timing")
A = [[1.0] * 8 for _ in range(8)]; d = {"A": A, "B": A, "C": [[0.0] * 8 for _ in range(8)]}
t = Sim(m, d).run([("zero", 2), ("load", 0, "A", 0, 0), ("load", 1, "B", 0, 0), ("mxu", 2, 0, 1), ("mxu", 2, 0, 1), ("store", 2, "C", 0, 0)]).cycles
report(t == 84, f"a six-instruction program takes 84 cycles (2 loads of {m.dma_cycles} = 40, two chained products = 16, fill {m.mxu_fill}, store {m.dma_cycles}: 40 + 8 + 8 + 8 + 20)", str(t))
A128, B128 = S.matrices(64, 64, 64); res = {}
for bi, bj, db in [(1, 1, False), (1, 1, True), (2, 2, True), (4, 4, False), (4, 4, True)]:
    sim, C = S.run(S.blocked(64, 64, 64, m, bi, bj, db), A128, B128, m); res[(bi, bj, db)] = sim
sim44 = res[(4, 4, True)]
report(sim44.cycles == sim44.dma_tiles * m.dma_cycles, f"4x4 double buffered on 64x64x64 is DMA-bound: {sim44.cycles} cycles = {sim44.dma_tiles} tiles x {m.dma_cycles}", f"{sim44.cycles} vs {sim44.dma_tiles * m.dma_cycles}")
lb = S.lower_bounds(64, 64, 64, m)
report(all(s.cycles >= lb["compute"] and s.cycles >= s.dma_tiles * m.dma_cycles for s in res.values()), f"no schedule beats the matrix-unit bound ({lb['compute']}) or its own DMA bound", str({k: v.cycles for k, v in res.items()}))
tiles_by_block = [S.expected_blocked_tiles(64, 64, 64, m, bi, bj) for bi, bj in [(1, 1), (1, 2), (2, 2), (2, 4), (4, 4)]]
report(all(x[0] > y[0] for x, y in zip(tiles_by_block, tiles_by_block[1:])), "more reuse moves fewer tiles: loads fall at every step from 1x1 to 1x2, 2x2, 2x4, 4x4: " + " > ".join(str(x[0]) for x in tiles_by_block), str(tiles_by_block))
report(res[(1, 1, True)].cycles < res[(1, 1, False)].cycles and res[(4, 4, True)].cycles < res[(4, 4, False)].cycles, "double buffering makes 1x1 and 4x4 faster", str({k: v.cycles for k, v in res.items()}))
errs = {}
for bi, bj in [(1, 1), (1, 8), (2, 2), (2, 4), (4, 4), (2, 8)]:
    sim, _ = S.run(S.blocked(64, 64, 64, m, bi, bj, True), A128, B128, m); errs[(bi, bj)] = S.predicted_double_buffered_cycles(64, 64, 64, m, bi, bj) / sim.cycles
report(all(1.0 <= e <= 1.12 for e in errs.values()), "the simple model (a step takes the longer of its loads and its products; first loads and stores do not overlap) is always a little ABOVE the simulator and within 12% for the double-buffered cycles: " + ", ".join(f"{k[0]}x{k[1]}: {v:.2f}" for k, v in errs.items()), str(errs))
print("-- 4. hazards (independent replay of the trace)")
report(not bad_haz, f"no read-before-write or write-before-read hazard in the traces of all {count} runs", str(bad_haz[:2]))
print("all checks pass" if failures == 0 else f"{failures} CHECK(S) FAILED"); sys.exit(1 if failures else 0)
