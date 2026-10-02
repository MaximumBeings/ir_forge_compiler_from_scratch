# A '?' dimension is never broadcast: the sizes must be equal when the program runs.
# The first call has one row, which matches the 1x3 bias. The second has two rows, so the run-time check aborts.
def plus_bias(a: tensor[?x3]) = a + [[1, 2, 3]]
print plus_bias([[10, 20, 30]])
print plus_bias([[10, 20, 30], [40, 50, 60]])
