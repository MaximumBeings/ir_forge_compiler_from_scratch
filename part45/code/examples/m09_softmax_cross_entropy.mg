# the stable softmax and a cross-entropy loss, as Chapter 31 uses them: loss = -sum(y * log_softmax(z)) / 2, y one-hot.
def log_softmax(z: tensor[2x3]) = z - row_max(z) - log(row_sum(exp(z - row_max(z))))
let z = [[0.7, -1.3, 2.1], [1.4, 0.2, -0.6]]
let y = [[0, 0, 1], [1, 0, 0]]
print col_sum(row_sum(y * log_softmax(z))) * -0.5
