#!/usr/bin/env python3
"""Chapter 40: what do loop order, blocking and double buffering do on GA-1? C = A @ B with 128 x 128 matrices (16 x 16 x 16 tiles of 8 x 8), one schedule per row, on a scratchpad
of 64 tile slots and on one of 16. Every result is checked against a plain triple loop before its cycles are reported. Output: sweep_orders_out.txt"""
from ga import Machine
import schedules as S
def table(slots):
    m = Machine(slots=slots); A, B = S.matrices(128, 128, 128); want = S.reference(A, B); lb = S.lower_bounds(128, 128, 128, m)
    print(f"scratchpad of {slots} tile slots ({slots * m.tile_words} words); matrix unit alone needs {lb['compute']} cycles, DMA alone (each tile moved once) {lb['dma']} cycles")
    print(f"{'schedule':<34} {'tiles moved':>11} {'cycles':>8} {'MXU util':>9} {'DMA busy':>9} {'vs best':>8} {'model, 2 buf':>13}")
    rows = []
    for name, build in [(f"blocked 1x1 (i,j,k){' ' * 0}", lambda db: S.blocked(128, 128, 128, m, 1, 1, db)), ("blocked 1x16 (row: i,k,j)", lambda db: S.blocked(128, 128, 128, m, 1, 16, db)),
                        ("blocked 2x2", lambda db: S.blocked(128, 128, 128, m, 2, 2, db)), ("blocked 2x4", lambda db: S.blocked(128, 128, 128, m, 2, 4, db)),
                        ("blocked 2x8", lambda db: S.blocked(128, 128, 128, m, 2, 8, db)), ("blocked 4x4", lambda db: S.blocked(128, 128, 128, m, 4, 4, db)), ("blocked 4x8", lambda db: S.blocked(128, 128, 128, m, 4, 8, db)), ("k outermost (k,i,j)", lambda db: S.kouter(128, 128, 128, m, db))]:
        for db in (False, True):
            try: prog = build(db)
            except ValueError: rows.append((f"{name}, {'double buffered' if db else 'single buffered'}", None)); continue
            sim, C = S.run(prog, A, B, m); assert C == want, name
            r = sim.report(); r["model"] = S.predicted_double_buffered_cycles(128, 128, 128, m, *map(int, name.split()[1].split("x"))) if (db and name.startswith("blocked")) else None
            rows.append((f"{name}, {'2 buf' if db else '1 buf'}", r))
    best = min(r["cycles"] for _, r in rows if r)
    for name, r in rows:
        if r is None: print(f"{name:<34} {'does not fit in the scratchpad':>40}")
        else: print(f"{name:<34} {r['dma_tiles']:>11} {r['cycles']:>8} {r['mxu_utilization']:>8.0%} {r['dma_busy']:>9.0%} {r['cycles'] / best:>7.2f}x" + (f" {r['model']:>8} ({r['model'] / r['cycles']:.2f})" if r["model"] else ""))
table(64); print(); table(16)
