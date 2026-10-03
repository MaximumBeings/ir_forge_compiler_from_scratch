#!/usr/bin/env python3
"""GA-1 plus the vector-unit instructions the back end of Chapter 41 needs (Chapter 40's simulator is imported unchanged and extended by subclassing):

  ("vscalar", op, dst, a, k, reversed)   dst := a (op) k, or k (op) a when reversed;  op in add sub mul div
  ("vop2", op, dst, a, b)                 elementwise compare / min: op in ge min  (ge gives 1.0 or 0.0)
  ("exp", dst, a) ("sqrt", dst, a) ("log", dst, a)   on the special-function path (exp overrides Chapter 40's so that it overflows to infinity, as IEEE arithmetic does)
  ("bcastrow", dst, a)                    dst[i][j] := a[0][j]
  ("bcastall", dst, a)                    dst[i][j] := a[0][0]
  ("trans", dst, a)                       dst := transpose(a)
  ("colred", op, dst, a)                  reduce each column of a with op in sum max, broadcast down the column
  ("masklen", slot, rows, cols, fill)     slot entries outside the first rows x cols become `fill` (0 for a sum, -inf for a max): hides the padding of a partial tile from a reduction
"""
import math
from ga import Machine, Sim

class Sim2(Sim):
    def run(self, program):
        m = self.m; T = m.T; S = self.spad
        for ins in program:
            op = ins[0]; vec = math.ceil(m.tile_words / m.vpu_lanes) + 1; sfu = math.ceil(m.tile_words / m.sfu_lanes) + 1
            if op == "vscalar":
                _, f, d, a, k, rev = ins; self._run("vpu", vec, (a,), (d,)); A = S[a]
                g = {"add": lambda x, y: x + y, "sub": lambda x, y: x - y, "mul": lambda x, y: x * y, "div": lambda x, y: x / y if y != 0 else float("inf") if x > 0 else float("-inf") if x < 0 else float("nan")}[f]
                S[d] = [[g(k, x) if rev else g(x, k) for x in row] for row in A]
            elif op == "vop2":
                _, f, d, a, b = ins; self._run("vpu", vec, (a, b), (d,)); A, B = S[a], S[b]
                S[d] = [[(1.0 if A[i][j] >= B[i][j] else 0.0) if f == "ge" else min(A[i][j], B[i][j]) for j in range(T)] for i in range(T)]
            elif op == "exp":                                         # IEEE behaviour on overflow (Python's math.exp raises): exp of a large number is infinity, as on the CPU path
                _, d, a = ins; self._run("vpu", sfu, (a,), (d,))
                def safe_exp(x):
                    try: return math.exp(x)
                    except OverflowError: return float("inf")
                S[d] = [[safe_exp(x) for x in row] for row in S[a]]
            elif op in ("sqrt", "log"):
                _, d, a = ins; self._run("vpu", sfu, (a,), (d,)); fn = (lambda x: math.sqrt(x) if x >= 0 else float("nan")) if op == "sqrt" else (lambda x: math.log(x) if x > 0 else float("-inf") if x == 0 else float("nan"))
                S[d] = [[fn(x) for x in row] for row in S[a]]
            elif op == "bcastrow":
                _, d, a = ins; self._run("vpu", vec, (a,), (d,)); S[d] = [list(S[a][0]) for _ in range(T)]
            elif op == "bcastall":
                _, d, a = ins; self._run("vpu", vec, (a,), (d,)); S[d] = [[S[a][0][0]] * T for _ in range(T)]
            elif op == "trans":
                _, d, a = ins; self._run("vpu", vec, (a,), (d,)); S[d] = [[S[a][j][i] for j in range(T)] for i in range(T)]
            elif op == "colred":
                _, f, d, a = ins; self._run("vpu", vec + 2, (a,), (d,)); fn = sum if f == "sum" else max
                col = [fn(S[a][i][j] for i in range(T)) for j in range(T)]; S[d] = [list(col) for _ in range(T)]
            elif op == "masklen":
                _, s, r, c, fill = ins; self._run("vpu", 1, (s,), (s,)); S[s] = [[S[s][i][j] if i < r and j < c else fill for j in range(T)] for i in range(T)]
            else: super().run([ins])
        return self
