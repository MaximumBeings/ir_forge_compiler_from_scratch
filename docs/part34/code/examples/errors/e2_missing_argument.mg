# ln_out takes three arguments (the row, the scale and the shift). Two is an arity error, reported before any code exists.
def ln_sigma(h: tensor[1x4]) = sqrt(row_mean((h - row_mean(h)) * (h - row_mean(h))) + 0.00001)
def ln_hat(h: tensor[1x4]) = (h - row_mean(h)) / ln_sigma(h)
def ln_out(h: tensor[1x4], gm: tensor[1x4], bt: tensor[1x4]) = ln_hat(h) * gm + bt
print ln_out([[1, 2, 3, 4]], [[1, 1, 1, 1]])
