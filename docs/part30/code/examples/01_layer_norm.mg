# Layer normalisation shifts each ROW (one token's features) to mean 0 and scales it to variance 1, then applies a per-feature scale g and shift b.
# Here g is all ones and b all zeros, so what is left is pure normalisation. The first row is 1 2 3 4: mean 2.5, variance 1.25, standard deviation 1.118.
def layer_norm(x: tensor[4x4], g: tensor[1x4], b: tensor[1x4]) = (x - row_mean(x)) / sqrt(row_mean((x - row_mean(x)) * (x - row_mean(x))) + 0.00001) * g + b
let x = [[1, 2, 3, 4], [10, 10, 10, 10], [-1, 0, 1, 0], [0, 0, 0, 8]]
print layer_norm(x, [[1, 1, 1, 1]], [[0, 0, 0, 0]])
# The same rows with a scale of 2 and a shift of 5: every normalised number is doubled, then 5 is added.
print layer_norm(x, [[2, 2, 2, 2]], [[5, 5, 5, 5]])
