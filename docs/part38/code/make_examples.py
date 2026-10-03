#!/usr/bin/env python3
"""Writes the Chapter 38 example programs: three programs with MANY top-level loop nests (so --outline does something), each small enough to read."""
import os
here = os.path.join(os.path.dirname(os.path.abspath(__file__)), "examples")
def write(name, text): open(os.path.join(here, name), "w").write(text)

L = ["# 35 loop nests in `main`: twelve rounds of three operations on two matrices (the very first add, `a + a`, adds a constant to itself and the compiler folds it into a",
     "# constant, so it makes no loop). --outline turns the 35 nests into 35 calls of FOUR functions: a product of a 3 x 3 with ITSELF (the first q), an add on 2 x 2, a product",
     "# of two 3 x 3 matrices, and a transpose of 3 x 3, however many rounds there are. (A function is outlined only when it has at least 32 top-level loop nests.)",
     "let a = [[1, 2], [3, 4]]", "let b = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]", "let p0 = a + a", "let q0 = b * b", "let r0 = transpose(b)"]
for i in range(1, 12): L += [f"let p{i} = p{i - 1} + a", f"let q{i} = q{i - 1} * b", f"let r{i} = transpose(r{i - 1})"]
L += ["print p11", "print q3", "print r11"]
write("01_four_distinct_nests.mg", "\n".join(L) + "\n")

L = ["# The same loop nest forty times: an add on 2 x 2 matrices. --outline turns the forty nests into forty calls of ONE function.", "let a = [[1, 2], [3, 4]]", "let s0 = a + a"]
for i in range(1, 40): L.append(f"let s{i} = s{i - 1} + a")
L.append("print s39")
write("02_one_nest_forty_times.mg", "\n".join(L) + "\n")

expr = " + ".join(["a"] * 40)
write("03_dynamic_shapes.mg", f"""# Dynamic shapes: a function over matrices of any size whose body has 39 loop nests (40 copies of `a`, added). The nests use the run-time sizes of `a` (values computed
# outside the nest), so the outlined function must take them as ARGUMENTS and not as constants. Called with a 2 x 3 matrix.
def forty(a: tensor[?x?]) = {expr}
let m = [[1, 2, 3], [4, 5, 6]]
print forty(m)
""")
write("04_below_threshold.mg", """# Only two loop nests (a product and a transpose; an add of constants would be folded away at compile time and make none): below the threshold of 32, so --outline leaves the function
# alone and no mg_outlined function appears.
let a = [[1, 2], [3, 4]]
let b = a * a
let c = transpose(b)
print c
""")
