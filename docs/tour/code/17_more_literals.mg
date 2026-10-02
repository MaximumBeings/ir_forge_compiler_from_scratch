# More about literals. Every literal is a matrix with at least one row and column; the shape is the count of rows by the count in each row.
print [[5]]                                    # one number is a 1x1 matrix, not a scalar (a bare 5 is the scalar)
print [[0.25, -0.5, 1e-3]]                     # decimals, negatives and scientific notation can mix in one row
print [[1, 2, 3, 4, 5, 6]]                     # a row: 1x6
print [[1], [2], [3], [4], [5], [6]]           # a column: 6x1
print transpose([[1, 2, 3, 4, 5, 6]])          # transposing the row gives the same column
print [[2, 4], [6, 8]] / 2                     # a scalar divides every element: [[1, 2], [3, 4]]
