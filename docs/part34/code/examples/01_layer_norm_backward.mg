# Backward through layer normalisation. y = (h - mean(h)) / sigma with sigma = sqrt(variance(h) + 0.00001), for ONE row of four numbers h.
# If the loss is L = sum(d * y) for a fixed upstream gradient d, the derivative of L with respect to h is
#     (d - mean(d) - y * mean(d * y)) / sigma
# (three terms, because every h_i changes the mean, the spread and so every y_j). The first matrix is that formula; the next four are the same
# derivatives found by brute force: nudge one entry of h by 0.01 up and by 0.01 down and watch L change.
def ln_sigma(h: tensor[1x4]) = sqrt(row_mean((h - row_mean(h)) * (h - row_mean(h))) + 0.00001)
def ln_hat(h: tensor[1x4]) = (h - row_mean(h)) / ln_sigma(h)
def loss(h: tensor[1x4], d: tensor[1x4]) = row_sum(d * ln_hat(h))
def backward(h: tensor[1x4], d: tensor[1x4]) = (d - row_mean(d) - ln_hat(h) * row_mean(d * ln_hat(h))) / ln_sigma(h)
let h = [[1, 2, 4, 8]]
let d = [[1, -2, 3, 0.5]]
print backward(h, d)
print (loss(h + [[0.01, 0, 0, 0]], d) - loss(h - [[0.01, 0, 0, 0]], d)) / 0.02
print (loss(h + [[0, 0.01, 0, 0]], d) - loss(h - [[0, 0.01, 0, 0]], d)) / 0.02
print (loss(h + [[0, 0, 0.01, 0]], d) - loss(h - [[0, 0, 0.01, 0]], d)) / 0.02
print (loss(h + [[0, 0, 0, 0.01]], d) - loss(h - [[0, 0, 0, 0.01]], d)) / 0.02
# Two things to see: the formula's four numbers add up to (nearly) zero (adding the same amount to every h changes nothing, so the gradients must cancel),
# and the brute-force numbers agree with the formula to about four digits (the step 0.01 and the six printed digits limit the agreement).
print row_sum(backward(h, d))
