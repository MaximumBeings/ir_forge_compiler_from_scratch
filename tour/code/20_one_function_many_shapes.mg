# '?' in a type: ONE compiled function serves any size. The shape of each result follows from the shapes of the arguments.
def gram(a: tensor[?x?]) = a @ transpose(a)                 # a times its own transpose: rows x rows
def total_per_column(a: tensor[?x?]) = col_sum(a)           # one total per column: 1 x columns
print gram([[1, 2]])                                         # 1x2 times 2x1 = 1x1: [[5]]
print gram([[1, 0], [0, 1], [1, 1]])                         # 3x2 times 2x3 = 3x3
print total_per_column([[1, 2, 3], [4, 5, 6]])               # [[5, 7, 9]]
print total_per_column([[1], [2], [3], [4]])                 # [[10]]
