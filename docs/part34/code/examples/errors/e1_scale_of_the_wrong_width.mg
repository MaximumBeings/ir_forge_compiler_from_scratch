# layer norm's scale is one number per feature: 1 x 4 here. A 1 x 3 scale does not fit, and the compiler says so.
def ln_sigma(h: tensor[1x4]) = sqrt(row_mean((h - row_mean(h)) * (h - row_mean(h))) + 0.00001)
def ln_hat(h: tensor[1x4]) = (h - row_mean(h)) / ln_sigma(h)
def ln_out(h: tensor[1x4], gm: tensor[1x4], bt: tensor[1x4]) = ln_hat(h) * gm + bt
print ln_out([[1, 2, 3, 4]], [[1, 1, 1]], [[0, 0, 0, 0]])
