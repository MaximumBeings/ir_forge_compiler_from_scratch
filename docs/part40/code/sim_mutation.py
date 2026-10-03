#!/usr/bin/env python3
"""READ THIS FIRST: this script writes WRONG versions of the GA-1 simulator (ga.py), one mistake each (a hazard rule dropped, a cost removed, a count wrong, a formula wrong), and runs
check_ga.py on each. A "caught" line is the EXPECTED, wanted result: it shows the checker can notice that mistake, and the line says which checks noticed. "NOT CAUGHT" would be a gap.
ga.py is restored afterwards. Output: sim_mutation_out.txt"""
import os, shutil, subprocess, sys
here = os.path.dirname(os.path.abspath(__file__)); G = os.path.join(here, "ga.py"); orig = open(G).read()
print("NOTE: this script deliberately breaks the simulator. 'caught' lines are EXPECTED: they show the checker can detect the mistake.")
def check():
    r = subprocess.run([sys.executable, os.path.join(here, "check_ga.py")], capture_output=True, text=True, cwd=here); return r
def kinds(r):
    fails = [l.strip()[5:].strip() for l in r.stdout.split("\n") if l.strip().startswith("FAIL")]
    names = {"result": "the results", "formula": "traffic", "six-instruction": "the hand-timed program", "DMA-bound": "the DMA-bound schedule", "beats": "the lower bounds", "more reuse": "reuse", "double buffering": "double buffering", "hazard": "the independent hazard replay"}
    out = []
    for f in fails:
        k = next((v for key, v in names.items() if key in f), "other")
        if k not in out: out.append(k)
    return fails, out
try:
    r = check(); print("baseline (nothing broken):", "checker passes (expected)" if r.returncode == 0 else "UNEXPECTED FAILURE")
    def mut(label, old, new):
        if old not in orig: print(f"{label}: MUTATION DID NOT APPLY"); return
        open(G, "w").write(orig.replace(old, new, 1)); r = check(); fails, k = kinds(r)
        if r.returncode != 0 and not fails: print(f"{label}: caught (the checker did not finish: {r.stderr.strip().splitlines()[-1][:100]})")
        elif fails: print(f"{label}: caught by {len(fails)} failing check(s) ({', '.join(k)})")
        else: print(f"{label}: NOT CAUGHT")
    mut("a write does not wait for the earlier READS of its slot (write-after-read hazard dropped)", "start = max(start, self.last_read[s], self.ready[s])", "start = max(start, self.ready[s])")
    mut("an instruction waits for only the FIRST of its source slots (the second operand is not waited for)", "for s in reads: start = max(start, self.ready[s])", "for s in reads[:1]: start = max(start, self.ready[s])")
    mut("a DMA transfer has no setup cost", "return self.dma_setup + math.ceil(self.tile_words / self.dma_words_per_cycle)", "return math.ceil(self.tile_words / self.dma_words_per_cycle)")
    mut("chained accumulating products wait for the fill time as well", "start = max(start, self.acc_ready[s], self.last_read[s])", "start = max(start, self.ready[s], self.last_read[s])")
    mut("the product's fill time is zero", "fill=m.mxu_fill)", "fill=0)")
    mut("each store is counted as two tile transfers", "self.dma_stores += 1", "self.dma_stores += 2")
    mut("a tile that sticks out of the matrix wraps around instead of being padded with zeros", "M[ti * T + i][tj * T + j] if ti * T + i < len(M) and tj * T + j < len(M[0]) else 0.0 for j in range(T)] for i in range(T)]", "M[(ti * T + i) % len(M)][(tj * T + j) % len(M[0])] for j in range(T)] for i in range(T)]")
    mut("a store writes the padding too (writes past the edge)", "if ti * T + i < len(M) and tj * T + j < len(M[0]): M[ti * T + i][tj * T + j] = S[s][i][j]", "M[ti * T + i][tj * T + j] = S[s][i][j]")
    mut("the matrix unit multiplies with A transposed", "C[i][j] + sum(A[i][k] * B[k][j] for k in range(T))", "C[i][j] + sum(A[k][i] * B[k][j] for k in range(T))")
    mut("all engines run in lock step (an instruction waits for every engine to be free)", "start = self.free[engine]", "start = max(self.free.values())")
    mut("a load does not wait for the slot to become free (no WAW either)", "for s in writes:\n            start = max(start, self.last_read[s], self.ready[s])", "for s in writes:\n            pass")
finally:
    open(G, "w").write(orig)
print("\nrestored:", "ga.py is back to its original" if open(G).read() == orig else "RESTORE FAILED")
