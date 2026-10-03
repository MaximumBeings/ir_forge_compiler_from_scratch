# Chapter 34's layer normalisation. The first print is the loss sum(d * ln_hat(h)); the second is Chapter 34's HAND-DERIVED gradient with respect to h.
# derivatives found by brute force: nudge one entry of h by 0.01 up and by 0.01 down and watch L change.
def ln_sigma(h: tensor[1x4]) = sqrt(row_mean((h - row_mean(h)) * (h - row_mean(h))) + 0.00001)
def ln_hat(h: tensor[1x4]) = (h - row_mean(h)) / ln_sigma(h)
def loss(h: tensor[1x4], d: tensor[1x4]) = row_sum(d * ln_hat(h))
def backward(h: tensor[1x4], d: tensor[1x4]) = (d - row_mean(d) - ln_hat(h) * row_mean(d * ln_hat(h))) / ln_sigma(h)
let h = [[1, 2, 4, 8]]
let d = [[1, -2, 3, 0.5]]
print loss(h, d)
print backward(h, d)
