# ge(a, b) compares: 1 where a >= b and 0 where it is not, element by element, with the same broadcasting as + - * /.
print ge([[1, 5, 3], [2, 2, 9]], [[2, 2, 2], [2, 2, 2]])       # which entries are at least 2?
print ge([[1, 5, 3], [2, 2, 9]], [[2], [9]])                    # a 2x1 column is stretched across the columns: row 0 against 2, row 1 against 9
# the one-hot row of the largest entry: compare a row with its own maximum (row_max gives a 2x1 column)
let scores = [[0.2, 0.7, 0.1], [0.5, 0.1, 0.4]]
print ge(scores, row_max(scores))
# a tie gives several 1s: both 0.5s reach the maximum
print ge([[0.5, 0.5, 0.0]], row_max([[0.5, 0.5, 0.0]]))
# a comparison against a number: write the number as a 1x1 matrix
print ge([[0.2, 0.7, 0.1]], [[0.5]])
