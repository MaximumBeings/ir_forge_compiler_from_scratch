# One dimension fixed, one dynamic: a has ?x2 rows, b is exactly 3x2.
# The first call's shapes agree. The second call passes a 2x2 for a: the runtime check aborts.
def bump(a: tensor[?x2], b: tensor[3x2]) = a + b
print bump([[1, 2], [3, 4], [5, 6]], [[10, 10], [10, 10], [10, 10]])
print bump([[1, 2], [3, 4]], [[10, 10], [10, 10], [10, 10]])
