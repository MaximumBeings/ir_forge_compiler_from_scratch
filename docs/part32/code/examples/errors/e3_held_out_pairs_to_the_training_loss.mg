# The held-out data have 4 pairs and the training loss was written for 10. Passing one where the other belongs is a shape error, caught when compiling.
def log_softmax10(s: tensor[10x5]) = s - row_max(s) - log(row_sum(exp(s - row_max(s))))
def train_loss(w: tensor[5x5], x: tensor[10x5], y: tensor[10x5]) = col_sum(row_sum(y * log_softmax10(x @ w))) * -0.1
let w = [[0, 0, 0, 0, 0], [0, 0, 0, 0, 0], [0, 0, 0, 0, 0], [0, 0, 0, 0, 0], [0, 0, 0, 0, 0]]
let xv = [[0, 0, 1, 0, 0], [0, 0, 0, 1, 0], [1, 0, 0, 0, 0], [0, 1, 0, 0, 0]]
let yv = [[0, 0, 0, 1, 0], [1, 0, 0, 0, 0], [0, 1, 0, 0, 0], [0, 0, 0, 0, 1]]
print train_loss(w, xv, yv)
