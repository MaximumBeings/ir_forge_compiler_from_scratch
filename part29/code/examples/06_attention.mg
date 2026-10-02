# Scaled dot-product attention for one head. Row i of q asks a question, row j of k advertises what position j holds, row j of v is what it
# hands over. scores[i][j] = how well question i matches key j; softmax turns each row of scores into weights; the output row i is the
# weighted average of the rows of v.   attention(q, k, v) = softmax(q @ transpose(k) / sqrt(d)) @ v      (here d = 2)
def softmax(s: tensor[3x3]) = exp(s - row_max(s)) / row_sum(exp(s - row_max(s)))
def weights(q: tensor[3x2], k: tensor[3x2]) = softmax(q @ transpose(k) * 0.7071067811865476)
def attention(q: tensor[3x2], k: tensor[3x2], v: tensor[3x2]) = weights(q, k) @ v
let q = [[1, 0], [0, 1], [1, 1]]
let k = [[1, 0], [0, 1], [1, 1]]
let v = [[10, 0], [0, 10], [5, 5]]
print weights(q, k)                      # 3x3, each row sums to 1
print attention(q, k, v)                 # 3x2: row i is the weights of row i times the three rows of v
