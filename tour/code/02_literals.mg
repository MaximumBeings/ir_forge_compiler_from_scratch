# Matrix literals: rows in brackets, numbers may be integers, decimals, negative, or scientific.
let a = [[1.5, -2, 3e2]]            # one row, three columns (1x3)
let b = [[1], [2], [3]]             # three rows, one column (3x1)
print a
print b
# A bare number is a scalar. It has no shape and can only be combined with a matrix.
let k = 4
print a * k
