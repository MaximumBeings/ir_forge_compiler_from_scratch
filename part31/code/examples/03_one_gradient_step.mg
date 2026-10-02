# One step of gradient descent by hand. Two tokens (0 and 1) and four (current, next) pairs: 0 -> 1, 0 -> 1, 0 -> 0, 1 -> 0.
# w starts at zero, so every probability is 1/2. The gradient of the loss is  transpose(x) @ (softmax(x @ w) - y) / 4.
# Row 0 of w sees three pairs: two push toward token 1, one toward token 0, so the gradient is [0.5, -0.5] / 4 = [0.125, -0.125]. Row 1 sees one pair (1 -> 0): [-0.125, 0.125].
def log_softmax(s: tensor[4x2]) = s - row_max(s) - log(row_sum(exp(s - row_max(s))))
def loss(w: tensor[2x2], x: tensor[4x2], y: tensor[4x2]) = col_sum(row_sum(y * log_softmax(x @ w))) * -0.25
def gradient(w: tensor[2x2], x: tensor[4x2], y: tensor[4x2]) = transpose(x) @ (exp(log_softmax(x @ w)) - y) * 0.25
let x = [[1, 0], [1, 0], [1, 0], [0, 1]]
let y = [[0, 1], [0, 1], [1, 0], [1, 0]]
let w = [[0, 0], [0, 0]]
print loss(w, x, y)                      # log(2) = 0.693147: with no information every token is a coin flip
print gradient(w, x, y)                  # [[0.125, -0.125], [-0.125, 0.125]]
let w1 = w - gradient(w, x, y)           # one step with learning rate 1
print w1                                 # [[-0.125, 0.125], [0.125, -0.125]]: each row moves toward the token that followed it more often
print loss(w1, x, y)                     # smaller than before: the step helped
