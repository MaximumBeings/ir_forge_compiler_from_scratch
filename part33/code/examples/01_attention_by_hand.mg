# Attention for one sequence of four tokens (1, 3, 2, 0), small enough to follow by hand. Each token has a 2-number key and a 2-number value.
# The query is (1, 0), so a token's score is just the first number of its key (times 1/sqrt(2) = 0.7071), and the second number of a value is 0 for tokens 1 and 3.
let x  = [[0, 1, 0, 0, 0], [0, 0, 0, 1, 0], [0, 0, 1, 0, 0], [1, 0, 0, 0, 0]]         # the four tokens, one-hot
let wk = [[0, 0], [2, 0], [1, 0], [1.5, 0], [0, 0]]                                      # key of each of the five tokens
let wv = [[1, 1], [10, 0], [0, 10], [5, 0], [0, 0]]                                      # value of each of the five tokens
let q  = [[1, 0]]
let scores = (x @ wk) @ transpose(q) * 0.7071067811865476        # 4x1: token 1 scores 2, token 3 scores 1.5, token 2 scores 1, token 0 scores 0 (all times 0.7071)
print scores
let a = exp(transpose(scores) - row_max(transpose(scores))) / row_sum(exp(transpose(scores) - row_max(transpose(scores))))      # softmax over the four scores: 1x4 attention weights
print a
print a @ (x @ wv)                                                # the attended value: the average of the four values, weighted by attention
