# Linear regression by gradient descent: the math, in Mountain Goat. The loop that repeats it is in the C++ driver (the language has none).
#
# The model is  prediction = x @ p,  where x has one row per sample and four columns (three features and a constant 1 for the bias),
# and p is the 4x1 column of parameters. The number of samples is dynamic (?); the number of columns is fixed at 4.
#
# grad  = x^T (x p - y)                          (half the gradient of the summed squared error)
# step  = p - rate * grad                        (one gradient-descent update; rate is passed as a 1x1 matrix: lr * 2 / number_of_samples)
# loss_sum = the sum of squared residuals        (1x1)
def grad(x: tensor[?x4], y: tensor[?x1], p: tensor[4x1]) = transpose(x) @ (x @ p - y)
def step(x: tensor[?x4], y: tensor[?x1], p: tensor[4x1], rate: tensor[1x1]) = p - rate * grad(x, y, p)
def loss_sum(x: tensor[?x4], y: tensor[?x1], p: tensor[4x1]) = col_sum((x @ p - y) * (x @ p - y))
