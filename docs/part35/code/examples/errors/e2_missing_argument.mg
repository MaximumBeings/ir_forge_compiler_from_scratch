# ln_back takes three arguments (the upstream gradient, the layer's input and the scale). Two is an arity error, reported before any code exists.
def ln_sigma(h: tensor[2x4]) = sqrt(row_mean((h - row_mean(h)) * (h - row_mean(h))) + 0.00001)
def ln_hat(h: tensor[2x4]) = (h - row_mean(h)) / ln_sigma(h)
def ln_back(d: tensor[2x4], h: tensor[2x4], g: tensor[1x4]) = ((d * g) - row_mean(d * g) - ln_hat(h) * row_mean((d * g) * ln_hat(h))) / ln_sigma(h)
print ln_back([[1, 2, 3, 4], [4, 3, 2, 1]], [[1, 2, 4, 8], [8, 4, 2, 1]])
