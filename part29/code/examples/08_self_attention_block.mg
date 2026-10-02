# Self-attention from token vectors: one matrix of 3 tokens (rows) of 4 numbers each is projected into queries, keys and values by three
# learned 4x2 matrices, attended over, and projected back to 4 numbers per token by a 2x4 matrix. The block's output is added to its input
# (a "residual connection"), so every token keeps what it had and gains what it attended to. (A def is one line, so it is long.)
def softmax(s: tensor[3x3]) = exp(s - row_max(s)) / row_sum(exp(s - row_max(s)))
def self_attention(x: tensor[3x4], wq: tensor[4x2], wk: tensor[4x2], wv: tensor[4x2], wo: tensor[2x4]) = x + softmax((x @ wq) @ transpose(x @ wk) * 0.7071067811865476) @ (x @ wv) @ wo
let x  = [[1, 0, 1, 0], [0, 1, 0, 0], [1, 1, 0, 1]]
let wq = [[1, 0], [0, 1], [1, 0], [0, 1]]
let wk = [[1, 0], [0, 1], [0, 1], [1, 0]]
let wv = [[1, 0], [0, 1], [1, 1], [0, 0]]
let wo = [[1, 0, 0, 1], [0, 1, 1, 0]]
print self_attention(x, wq, wk, wv, wo)
