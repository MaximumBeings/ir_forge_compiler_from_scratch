# A matrix product is the simplest contraction: sum over axis 1 of A (the columns) against axis 0 of B (the rows). The appendix's first example.
let a = [[1, 2], [3, 4], [5, 6]]
let b = [[1, 0, 2, 1], [0, 1, 1, 2]]
print contract(a, (1), b, (0))     # 3x4, equal to a @ b
print a @ b                         # the same numbers, written with the operator
