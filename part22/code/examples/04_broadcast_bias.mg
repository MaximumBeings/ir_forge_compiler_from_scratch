# Broadcasting: a size-1 dimension is repeated to fit. Add a 1x3 row to every row of a 2x3 matrix.
let a = [[1, 2, 3], [4, 5, 6]]
let bias = [[100, 200, 300]]
print a + bias
let col = [[10], [20]]
print a + col                     # a 2x1 column is repeated across the columns
print a * [[2]]                   # a 1x1 matrix is repeated in both directions
