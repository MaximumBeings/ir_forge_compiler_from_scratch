# attention was defined for 3 tokens of width 2. Passing 4 tokens does not fit the parameter shapes, and the compiler says so.
def softmax(s: tensor[3x3]) = exp(s - row_max(s)) / row_sum(exp(s - row_max(s)))
def weights(q: tensor[3x2], k: tensor[3x2]) = softmax(q @ transpose(k))
let four = [[1, 0], [0, 1], [1, 1], [2, 2]]
print weights(four, four)
