# A tiny "linear layer": y = x @ w + bias, with x 2x3 (two samples), w 3x2, bias 2x2.
def layer(x: tensor[2x3], w: tensor[3x2], bias: tensor[2x2]) = x @ w + bias
print layer([[1, 2, 3], [4, 5, 6]], [[1, 0], [0, 1], [1, 1]], [[0.5, 0.5], [0.5, 0.5]])
