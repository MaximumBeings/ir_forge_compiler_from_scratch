# Dividing the scores by a "temperature" T before the softmax sharpens it (T < 1) or flattens it (T > 1). T is a compile-time number.
def softmax(x: tensor[1x3]) = exp(x - row_max(x)) / row_sum(exp(x - row_max(x)))
let scores = [[1, 2, 3]]
print softmax(scores)               # T = 1
print softmax(scores / 0.5)         # T = 0.5: sharper, the top score takes about 87% (exp(4) against exp(2) and 1)
print softmax(scores / 4)           # T = 4: flatter, close to a third each
