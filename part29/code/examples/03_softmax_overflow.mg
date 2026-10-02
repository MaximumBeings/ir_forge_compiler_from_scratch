# THE GOTCHA the "naive" name was warning about. e^1000 is larger than any double can hold, so exp gives infinity,
# and infinity / infinity is "not a number" (nan). The formula is right on paper and wrong on a computer.
def softmax_naive(x: tensor[1x3]) = exp(x) / row_sum(exp(x))
print exp([[1000, 1001, 1002]])
print softmax_naive([[1000, 1001, 1002]])
