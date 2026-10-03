#!/usr/bin/env python3
"""GA-1: a MODEL of a small matrix accelerator, written in plain Python. It is not a chip and not a design for one: it is a cycle-counting simulator with the three things
that decide the speed of an inference accelerator, so that the effect of tiling and loop order on them can be measured:

  * a DMA engine that moves one TILE (T x T words) between off-chip memory ("DRAM") and an on-chip SCRATCHPAD of a few tile slots, taking setup + words / bandwidth cycles;
  * a MATRIX UNIT that multiplies two T x T tiles and adds the product to a third (C += A @ B), one tile product every `mxu_cycles` cycles;
  * a VECTOR UNIT (elementwise, with a slower special-function path for exp) and reductions, used from Chapter 41 on.

Each engine (DMA, matrix unit, vector unit) has its own in-order queue and the engines run independently of each other (decoupled access/execute, as in real accelerators); an
instruction starts when its engine is free, its operands are ready and the slots it overwrites are no longer needed (so a program that gets its loads ahead of its multiplies, into
slots that are free, overlaps the DMA with the matrix unit; a program that has no free slots to load into, waits). Every instruction really computes its result on
real numbers, in program order (so the result of a schedule is what its instructions say, whatever the timing); the TIMING rule enforces the hazards, and an optional trace of every
instruction's start and finish lets an independent checker (check_ga.py) verify that no instruction read a slot before it was written or overwrote one still being read. All the numbers below are assumptions of the model, chosen to be
plausible in ratio (the matrix unit is much faster than the DMA), not measurements of any real device."""
import math
from dataclasses import dataclass, field

@dataclass
class Machine:
    T: int = 8                     # tile edge: tiles are T x T words
    slots: int = 16                # scratchpad capacity, in tiles
    dma_setup: int = 16            # cycles of fixed cost per tile transfer
    dma_words_per_cycle: int = 16  # DMA bandwidth once started (one transfer at a time)
    mxu_cycles: int = 8            # the matrix unit accepts a new tile product every this many cycles (T x T x T MACs: T x T = 64 MACs per cycle)
    mxu_fill: int = 8              # extra cycles before a product can be READ by another engine (accumulating into it again needs no extra wait)
    vpu_lanes: int = 16            # elementwise lanes
    sfu_lanes: int = 4             # lanes of the special-function path (exp)
    @property
    def tile_words(self): return self.T * self.T
    @property
    def dma_cycles(self): return self.dma_setup + math.ceil(self.tile_words / self.dma_words_per_cycle)
    @property
    def peak_macs_per_cycle(self): return self.T ** 3 / self.mxu_cycles

# Instruction = (op, operands...). Slots are integers 0..slots-1; tensors are names in the machine's DRAM; (ti, tj) are tile coordinates.
#   ("load", slot, name, ti, tj)    DMA: DRAM tile -> slot (a tile that sticks out of the tensor is zero-padded)
#   ("store", slot, name, ti, tj)   DMA: slot -> DRAM tile (only the part inside the tensor is written)
#   ("zero", slot)                  vector unit: slot := 0
#   ("mxu", c, a, b)                matrix unit: slot c += slot a @ slot b
#   ("vop", op, dst, a, b)          vector unit, elementwise on tiles: op in add sub mul div max ; b may be None for unary op in relu neg
#   ("exp", dst, a)                 special-function path
#   ("vscale", dst, a, k)           dst := a * k   (k a number)
#   ("rowred", op, dst, a)          reduce each row of a with op in sum max, and broadcast the result across the row of dst
#   ("bcastcol", dst, a)            dst[i][j] := a[i][0]   (column 0 spread across the row)
#   ("masklen", slot, rows, cols)   vector unit: zero the part of the tile outside the first rows x cols entries (used after a padded load)
class Sim:
    def __init__(self, machine, dram):
        self.m = machine; self.dram = dram                 # dram: name -> list of rows (floats)
        T = machine.T; self.spad = [[[0.0] * T for _ in range(T)] for _ in range(machine.slots)]
        self.free = {"dma": 0, "mxu": 0, "vpu": 0}; self.busy = {"dma": 0, "mxu": 0, "vpu": 0}
        self.ready = [0] * machine.slots; self.acc_ready = [0] * machine.slots; self.last_read = [0] * machine.slots
        self.end = 0
        self.trace = []                                 # (index, engine, start, finish, reads, writes) for every instruction, for the independent hazard check
        self.dma_tiles = 0; self.dma_loads = 0; self.dma_stores = 0; self.macs = 0; self.instructions = 0
    # ---- the timing rule, in one place
    def _run(self, engine, duration, reads, writes, acc=(), fill=0):
        start = self.free[engine]                       # each engine runs its own instructions in order; engines run independently of each other
        for s in reads: start = max(start, self.ready[s])
        for s in acc: start = max(start, self.acc_ready[s], self.last_read[s])
        for s in writes:
            start = max(start, self.last_read[s], self.ready[s])
        finish = start + duration
        self.free[engine] = finish; self.busy[engine] += duration
        for s in reads: self.last_read[s] = max(self.last_read[s], finish)
        for s in acc: self.last_read[s] = max(self.last_read[s], finish)
        for s in tuple(writes) + tuple(acc): self.ready[s] = finish + fill; self.acc_ready[s] = finish
        self.end = max(self.end, finish + fill); self.instructions += 1
        self.trace.append((self.instructions - 1, engine, start, finish, tuple(reads) + tuple(acc), tuple(writes) + tuple(acc), fill))
        return start, finish
    def tile(self, name, ti, tj):
        T = self.m.T; M = self.dram[name]
        return [[M[ti * T + i][tj * T + j] if ti * T + i < len(M) and tj * T + j < len(M[0]) else 0.0 for j in range(T)] for i in range(T)]
    def run(self, program):
        m = self.m; T = m.T; S = self.spad
        for ins in program:
            op = ins[0]
            if op == "load":
                _, s, name, ti, tj = ins; self._run("dma", m.dma_cycles, (), (s,)); S[s] = self.tile(name, ti, tj); self.dma_tiles += 1; self.dma_loads += 1
            elif op == "store":
                _, s, name, ti, tj = ins; self._run("dma", m.dma_cycles, (s,), ()); M = self.dram[name]
                for i in range(T):
                    for j in range(T):
                        if ti * T + i < len(M) and tj * T + j < len(M[0]): M[ti * T + i][tj * T + j] = S[s][i][j]
                self.dma_tiles += 1; self.dma_stores += 1
            elif op == "zero":
                _, s = ins; self._run("vpu", 1, (), (s,)); S[s] = [[0.0] * T for _ in range(T)]
            elif op == "mxu":
                _, c, a, b = ins; self._run("mxu", m.mxu_cycles, (a, b), (), acc=(c,), fill=m.mxu_fill)       # c is read and written (accumulated): chained products wait for acc_ready, other readers for ready (= finish + fill)
                A, B, C = S[a], S[b], S[c]
                S[c] = [[C[i][j] + sum(A[i][k] * B[k][j] for k in range(T)) for j in range(T)] for i in range(T)]; self.macs += T ** 3
            elif op == "vop":
                _, f, d, a, b = ins; dur = math.ceil(m.tile_words / m.vpu_lanes) + 1
                self._run("vpu", dur, (a,) + ((b,) if b is not None else ()), (d,)); A = S[a]; B = S[b] if b is not None else None
                fn = {"add": lambda x, y: x + y, "sub": lambda x, y: x - y, "mul": lambda x, y: x * y, "div": lambda x, y: x / y if y != 0 else float("inf") if x > 0 else float("-inf") if x < 0 else float("nan"),
                      "max": lambda x, y: max(x, y), "relu": lambda x, y: max(x, 0.0), "neg": lambda x, y: -x}[f]
                S[d] = [[fn(A[i][j], B[i][j] if B is not None else 0.0) for j in range(T)] for i in range(T)]
            elif op == "exp":
                _, d, a = ins; self._run("vpu", math.ceil(m.tile_words / m.sfu_lanes) + 1, (a,), (d,)); S[d] = [[math.exp(x) for x in row] for row in S[a]]
            elif op == "vscale":
                _, d, a, k = ins; self._run("vpu", math.ceil(m.tile_words / m.vpu_lanes) + 1, (a,), (d,)); S[d] = [[x * k for x in row] for row in S[a]]
            elif op == "rowred":
                _, f, d, a = ins; self._run("vpu", math.ceil(m.tile_words / m.vpu_lanes) + 3, (a,), (d,)); fn = sum if f == "sum" else max
                S[d] = [[fn(row)] * T for row in S[a]]
            elif op == "bcastcol":
                _, d, a = ins; self._run("vpu", math.ceil(m.tile_words / m.vpu_lanes) + 1, (a,), (d,)); S[d] = [[row[0]] * T for row in S[a]]
            elif op == "masklen":
                _, s, r, c = ins; self._run("vpu", 1, (s,), (s,)); S[s] = [[S[s][i][j] if i < r and j < c else 0.0 for j in range(T)] for i in range(T)]
            else: raise ValueError(op)
        return self
    @property
    def cycles(self): return self.end
    def report(self):
        c = max(self.cycles, 1)
        return dict(cycles=self.cycles, dma_tiles=self.dma_tiles, loads=self.dma_loads, stores=self.dma_stores, macs=self.macs, instructions=self.instructions,
                    mxu_utilization=self.macs / (self.m.peak_macs_per_cycle * c), dma_busy=self.busy["dma"] / c, mxu_busy=self.busy["mxu"] / c, vpu_busy=self.busy["vpu"] / c)
