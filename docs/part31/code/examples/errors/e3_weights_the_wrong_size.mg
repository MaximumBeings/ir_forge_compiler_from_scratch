# The weights must be 5x5 (one row per token, one column per next token). A 4x5 matrix does not fit.
def log_softmax(s: tensor[14x5]) = s - row_max(s) - log(row_sum(exp(s - row_max(s))))
def loss(w: tensor[5x5], x: tensor[14x5], y: tensor[14x5]) = col_sum(row_sum(y * log_softmax(x @ w))) * -0.07142857142857142
def gradient(w: tensor[5x5], x: tensor[14x5], y: tensor[14x5]) = transpose(x) @ (exp(log_softmax(x @ w)) - y) * 0.07142857142857142
def step(w: tensor[5x5], x: tensor[14x5], y: tensor[14x5]) = w - gradient(w, x, y) * 8
let w = [[0, 0, 0, 0, 0], [0, 0, 0, 0, 0], [0, 0, 0, 0, 0], [0, 0, 0, 0, 0]]
let x = [[1, 0, 0, 0, 0], [0, 1, 0, 0, 0], [0, 0, 1, 0, 0], [1, 0, 0, 0, 0], [0, 1, 0, 0, 0], [0, 0, 0, 1, 0], [1, 0, 0, 0, 0], [0, 1, 0, 0, 0], [0, 0, 1, 0, 0], [1, 0, 0, 0, 0], [0, 0, 1, 0, 0], [0, 0, 0, 1, 0], [1, 0, 0, 0, 0], [0, 1, 0, 0, 0]]
let y = [[0, 1, 0, 0, 0], [0, 0, 1, 0, 0], [1, 0, 0, 0, 0], [0, 1, 0, 0, 0], [0, 0, 0, 1, 0], [1, 0, 0, 0, 0], [0, 1, 0, 0, 0], [0, 0, 1, 0, 0], [1, 0, 0, 0, 0], [0, 0, 1, 0, 0], [0, 0, 0, 1, 0], [1, 0, 0, 0, 0], [0, 1, 0, 0, 0], [0, 0, 0, 0, 1]]
print step(w, x, y)
