# The model was written for 4 tokens. Three tokens do not fit the 4x4 parameter of layer_norm, and the compiler says so.
def layer_norm(x: tensor[4x4], g: tensor[1x4], b: tensor[1x4]) = (x - row_mean(x)) / sqrt(row_mean((x - row_mean(x)) * (x - row_mean(x))) + 0.00001) * g + b
print layer_norm([[1, 2, 3, 4], [4, 3, 2, 1], [0, 1, 0, 1]], [[1, 1, 1, 1]], [[0, 0, 0, 0]])
