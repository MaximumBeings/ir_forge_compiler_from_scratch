# softmax turns each row of scores into probabilities: positive numbers that add up to 1, bigger score = bigger share.
#   softmax(row)_j = e^(row_j) / (e^(row_0) + e^(row_1) + ...)
# exp(x) is 2x3, row_sum(...) is 2x1: the size-1 column is stretched across the three columns (Chapter 22's broadcasting).
def softmax_naive(x: tensor[2x3]) = exp(x) / row_sum(exp(x))
let scores = [[1, 2, 3], [0, 0, 0]]
print softmax_naive(scores)                        # row 0: [0.0900306, 0.244728, 0.665241]; row 1: three equal scores -> a third each
print row_sum(softmax_naive(scores))               # every row of probabilities sums to 1
