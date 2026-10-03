# layer normalisation weighted by a fixed matrix: sqrt, division, row means.
def ln_sigma(h: tensor[2x4]) = sqrt(row_mean((h - row_mean(h)) * (h - row_mean(h))) + 0.00001)
def ln_hat(h: tensor[2x4]) = (h - row_mean(h)) / ln_sigma(h)
let h = [[1.0, 2.5, 4.0, 8.0], [0.3, -1.2, 2.2, 0.7]]
let d = [[1.0, -2.0, 3.0, 0.5], [0.4, 1.5, -0.7, 2.0]]
print col_sum(row_sum(d * ln_hat(h)))
