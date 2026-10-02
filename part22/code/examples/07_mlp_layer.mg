# One neural-network layer: relu(x @ w + bias). Two samples, three inputs, two outputs.
def layer(x: tensor[2x3], w: tensor[3x2], bias: tensor[1x2]) = relu(x @ w + bias)
print layer([[1, 2, 3], [-1, -2, -3]], [[1, -1], [0, 1], [1, 0]], [[0.5, -10]])
