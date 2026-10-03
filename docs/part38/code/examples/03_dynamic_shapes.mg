# Dynamic shapes: a function over matrices of any size whose body has 39 loop nests (40 copies of `a`, added). The nests use the run-time sizes of `a` (values computed
# outside the nest), so the outlined function must take them as ARGUMENTS and not as constants. Called with a 2 x 3 matrix.
def forty(a: tensor[?x?]) = a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a
let m = [[1, 2, 3], [4, 5, 6]]
print forty(m)
