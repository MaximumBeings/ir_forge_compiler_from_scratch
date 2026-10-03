#!/usr/bin/env python3
"""Hand-written GA-1 programs for C = A @ B, in two families, and the helpers that run and check them.

  blocked(M, K, N, bi, bj, double_buffer): "output-stationary" schedules. A block of bi x bj tiles of C stays in the scratchpad while the K dimension is streamed through it:
        for each block of C:  zero it;  for each k: load bi tiles of A and bj tiles of B, do bi*bj tile products;  store the block.
      bi = bj = 1 is the plain (i, j, k) loop order; bi = 1, bj = (all tiles of a row) is the (i, k, j) order of Chapter 24 (a row of C stays, a tile of A is reused across the row);
      bigger blocks reuse both. With double_buffer the loads for step k+1 are issued BEFORE the products of step k, into a second set of slots.
  kouter(M, K, N, double_buffer): the (k, i, j) loop order: every tile of C is read from DRAM, updated by one tile product and written back for each k.
Every program is checked against a plain triple loop by check_ga.py."""
import math
from ga import Machine, Sim

def tiles(n, T): return math.ceil(n / T)

def blocked(M, K, N, m, bi, bj, double_buffer=True, a="A", b="B", c="C"):
    Mt, Kt, Nt = tiles(M, m.T), tiles(K, m.T), tiles(N, m.T); nbuf = 2 if double_buffer else 1
    need = bi * bj + nbuf * (bi + bj)
    if need > m.slots: raise ValueError(f"blocked({bi},{bj}, double_buffer={double_buffer}) needs {need} slots, the scratchpad has {m.slots}")
    Cs = lambda x, y: x * bj + y                                        # slot of C tile (x, y) of the block
    As = lambda buf, x: bi * bj + buf * (bi + bj) + x
    Bs = lambda buf, y: bi * bj + buf * (bi + bj) + bi + y
    prog = []
    for I in range(0, Mt, bi):
        for J in range(0, Nt, bj):
            ii = [i for i in range(I, min(I + bi, Mt))]; jj = [j for j in range(J, min(J + bj, Nt))]
            for x in range(len(ii)):
                for y in range(len(jj)): prog.append(("zero", Cs(x, y)))
            def loads(k, buf):
                for x, i in enumerate(ii): prog.append(("load", As(buf, x), a, i, k))
                for y, j in enumerate(jj): prog.append(("load", Bs(buf, y), b, k, j))
            if double_buffer: loads(0, 0)
            for k in range(Kt):
                if double_buffer:
                    if k + 1 < Kt: loads(k + 1, (k + 1) % 2)
                    buf = k % 2
                else: loads(k, 0); buf = 0
                for x in range(len(ii)):
                    for y in range(len(jj)): prog.append(("mxu", Cs(x, y), As(buf, x), Bs(buf, y)))
            for x, i in enumerate(ii):
                for y, j in enumerate(jj): prog.append(("store", Cs(x, y), c, i, j))
    return prog

def kouter(M, K, N, m, double_buffer=True, a="A", b="B", c="C"):
    Mt, Kt, Nt = tiles(M, m.T), tiles(K, m.T), tiles(N, m.T); groups = 2 if double_buffer else 1
    if 3 * groups > m.slots: raise ValueError("scratchpad too small")
    prog = []; g = 0
    for k in range(Kt):
        for i in range(Mt):
            for j in range(Nt):
                sc, sa, sb = 3 * g, 3 * g + 1, 3 * g + 2; g = (g + 1) % groups
                if k == 0: prog.append(("zero", sc))
                else: prog.append(("load", sc, c, i, j))               # the partial sum comes back from DRAM
                prog += [("load", sa, a, i, k), ("load", sb, b, k, j), ("mxu", sc, sa, sb), ("store", sc, c, i, j)]
    return prog

def matrices(M, K, N, seed=1):
    import random; r = random.Random(seed)
    A = [[r.randint(-3, 3) for _ in range(K)] for _ in range(M)]; B = [[r.randint(-3, 3) for _ in range(N)] for _ in range(K)]
    return A, B

def reference(A, B):
    return [[sum(A[i][k] * B[k][j] for k in range(len(B))) for j in range(len(B[0]))] for i in range(len(A))]

def run(program, A, B, m):
    dram = {"A": A, "B": B, "C": [[0.0] * len(B[0]) for _ in range(len(A))]}
    sim = Sim(m, dram).run(program); return sim, dram["C"]

def lower_bounds(M, K, N, m):
    """The two simple bounds: the matrix unit alone, and the DMA alone moving the tiles that MUST move at least once (A, B in; C out)."""
    Mt, Kt, Nt = tiles(M, m.T), tiles(K, m.T), tiles(N, m.T)
    return dict(compute=Mt * Nt * Kt * m.mxu_cycles, dma=(Mt * Kt + Kt * Nt + Mt * Nt) * m.dma_cycles)

def expected_blocked_tiles(M, K, N, m, bi, bj):
    """Tiles moved by blocked(): for every block, bi_eff + bj_eff loads per k, and one store per C tile."""
    Mt, Kt, Nt = tiles(M, m.T), tiles(K, m.T), tiles(N, m.T); loads = 0
    for I in range(0, Mt, bi):
        for J in range(0, Nt, bj): loads += Kt * (min(bi, Mt - I) + min(bj, Nt - J))
    return loads, Mt * Nt

def predicted_double_buffered_cycles(M, K, N, m, bi, bj):
    """A simple model of a double-buffered blocked schedule: per k step the DMA needs (bi + bj) tile loads and the matrix unit bi * bj products, and with double buffering the two
    overlap, so a step takes the LONGER of the two; each block also pays its first loads before the first product and its stores after the last (nothing overlaps them)."""
    Mt, Kt, Nt = tiles(M, m.T), tiles(K, m.T), tiles(N, m.T); blocks = math.ceil(Mt / bi) * math.ceil(Nt / bj)
    load = (bi + bj) * m.dma_cycles; comp = bi * bj * m.mxu_cycles
    return blocks * (Kt * max(load, comp) + load + bi * bj * m.dma_cycles)
