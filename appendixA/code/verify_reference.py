#!/usr/bin/env python3
"""Appendix A: runs every snippet of the language reference through the real compiler (mgc run) and compares the result with what the appendix states. Writes reference_out.txt (the snippet and
what the compiler printed, which the page embeds) and exits 1 if any result differs from the stated one, so the reference cannot drift from the compiler.
Each case: (heading, source, expected) where expected is a matrix (list of rows) or ('error', text that the message must contain)."""
import os, re, subprocess, sys, tempfile
here = os.path.dirname(os.path.abspath(__file__)); MGC = os.path.join(here, "..", "..", "part44", "code", "mgc")   # the newest mgc (Chapter 44)
sys.path.insert(0, os.path.join(here, "..", "..", "part46", "code")); import common; common.MGC = MGC; from common import run_matrices
E = lambda s: ("error", s)
CASES = [
 ("Scalars are numbers, not values: they cannot be printed alone", "print 2 + 3", E("print needs a matrix")),
 ("A matrix and a scalar combine elementwise", "print [[1, 2], [3, 4]] * 2 + 1", [[3, 5], [7, 9]]),
 ("Unary minus", "print -[[1, -2]]", [[-1, 2]]),
 ("Matrix product with @ (inner sizes meet)", "print [[1, 2, 3], [4, 5, 6]] @ [[1], [0], [2]]", [[7], [16]]),
 ("Precedence: * and @ bind tighter than +, and are left to right", "print 2 * [[1, 2]] @ [[3], [4]]", [[22]]),
 ("A size-1 dimension stretches (row vector against matrix)", "print [[1, 2], [3, 4]] - [[1, 1]]", [[0, 1], [2, 3]]),
 ("A size-1 dimension stretches (column vector against matrix)", "print [[1, 2], [3, 4]] / [[2], [4]]", [[0.5, 1], [0.75, 1]]),
 ("A scalar can be bound with let and used, but not printed", "let s = 2\nprint [[1, 2]] * s", [[2, 4]]),
 ("let binds a name; a later let of the same name replaces it", "let a = [[1, 2]]\nlet a = [[3, 4]]\nprint a", [[3, 4]]),
 ("def: a function of tensors, checked at every call", "def f(x: tensor[2x2]) = x * 2\nprint f([[1, 2], [3, 4]])", [[2, 4], [6, 8]]),
 ("def with a dynamic dimension, written ?", "def f(x: tensor[?x2]) = x * 2\nprint f([[1, 2], [3, 4], [5, 6]])", [[2, 4], [6, 8], [10, 12]]),
 ("Reductions: col_mean leaves one value per column (1xC)", "print col_mean([[1, 2], [3, 4]])", [[2, 3]]),
 ("Reductions: row_max leaves one value per row (Rx1)", "print row_max([[1, 5, 2], [7, 0, 3]])", [[5], [7]]),
 ("transpose swaps the two sizes", "print transpose([[1, 2, 3]])", [[1], [2], [3]]),
 ("reshape: the same elements in another shape", "print reshape([[1, 2, 3, 4]], 2, 2)", [[1, 2], [3, 4]]),
 ("ge: 1 where a >= b, else 0 (a comparison)", "print ge([[1, 5]], [[3, 3]])", [[0, 1]]),
 ("The elementwise functions", "print sqrt([[4, 9]]) + log([[1]]) + exp([[0]]) + relu([[-1, 2]])", [[3, 6]]),
 ("contract: sum of products over paired axes (here an ordinary matrix product)", "print contract([[1, 2], [3, 4]], (1), [[1, 0], [0, 1]], (0))", [[1, 2], [3, 4]]),
 ("A comment runs to the end of the line", "print [[1, 2]]   # trailing comment", [[1, 2]]),
 ("Error: an unknown name", "print b", E("unknown name 'b'")),
 ("Error: rows of different lengths", "print [[1, 2], [3]]", E("matrix rows have different lengths")),
 ("Error: shapes that do not fit", "print [[1, 2]] + [[1, 2, 3]]", E("cannot add shapes 1x2 and 1x3")),
 ("Error: inner dimensions of @ differ", "print [[1, 2]] @ [[1, 2]]", E("inner dimensions differ")),
 ("Error: @ with a scalar", "print [[1, 2], [3, 4]] @ 2", E("needs two matrices, not a scalar")),
 ("Error: an argument that does not fit its parameter", "def f(x: tensor[2x2]) = x * 2\nprint f([[1, 2, 3]])", E("does not fit parameter 2x2")),
 ("Error: there are no loops", "for i in 3", E("a statement must start with 'let', 'print' or 'def'")),
 ("Error: an incomplete expression", "print 1 +", E("expected an expression")),
]
def render(m): return "\n".join("[" + ", ".join(("%g" % v) for v in row) + "]" for row in m)
fails = 0; out = []; tmp = os.path.join(tempfile.mkdtemp(prefix="apxA_"), "s.mg")
for head, src, exp in CASES:
    open(tmp, "w").write(src + "\n"); r = subprocess.run([MGC, "run", tmp], capture_output=True, text=True)
    if isinstance(exp, tuple):
        msg = re.search(r"error: (.*)", r.stderr); got = msg.group(1) if msg else ""; ok = r.returncode != 0 and exp[1] in got; shown = "error: " + got
    else:
        got = run_matrices(tmp) if r.returncode == 0 else None; ok = got is not None and len(got) == 1 and got[0] == [[float(x) for x in row] for row in exp]; shown = render(got[0]) if got else "(failed) " + r.stderr[:100]
    fails += not ok
    out.append(f"## {head}\n\n{src}\n\n=> {shown}\n" + ("" if ok else "   ** DIFFERS from the stated result **\n"))
open(os.path.join(here, "reference_out.txt"), "w").write("\n".join(out)); print(f"{len(CASES) - fails} of {len(CASES)} snippets give the stated result"); sys.exit(1 if fails else 0)
