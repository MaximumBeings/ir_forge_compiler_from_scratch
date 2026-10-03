# The mask must be as large as the score matrix: 6 x 6 here. A 4 x 4 mask does not fit, and the compiler says so.
def softmax_rows(m: tensor[6x6]) = exp(m - row_max(m)) / row_sum(exp(m - row_max(m)))
let scores = [[1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1]]
let mask = [[0, -1000000000, -1000000000, -1000000000], [0, 0, -1000000000, -1000000000], [0, 0, 0, -1000000000], [0, 0, 0, 0]]
print softmax_rows(scores + mask)
