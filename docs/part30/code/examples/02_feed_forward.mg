# The feed-forward network: expand to 8 features, keep only the positive ones (relu), contract back to 4.
# With w1 = [I | -I] (an identity next to a negated identity) and w2 = [I ; -I] the hidden layer holds relu(x) next to relu(-x), and the output
# is relu(x) - relu(-x), which is x itself: two relus can build a straight line. The numbers below confirm it.
def ffn(x: tensor[4x4], w1: tensor[4x8], b1: tensor[1x8], w2: tensor[8x4], b2: tensor[1x4]) = relu(x @ w1 + b1) @ w2 + b2
let x = [[1, -2, 0, 3], [-1, 1, -1, 1], [0, 0, 0, 0], [5, -5, 2, -2]]
let w1 = [[1, 0, 0, 0, -1, 0, 0, 0], [0, 1, 0, 0, 0, -1, 0, 0], [0, 0, 1, 0, 0, 0, -1, 0], [0, 0, 0, 1, 0, 0, 0, -1]]
let w2 = [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1], [-1, 0, 0, 0], [0, -1, 0, 0], [0, 0, -1, 0], [0, 0, 0, -1]]
let zero8 = [[0, 0, 0, 0, 0, 0, 0, 0]]
let zero4 = [[0, 0, 0, 0]]
print ffn(x, w1, zero8, w2, zero4)
# A bias moves the hidden features before the relu: a bias of -1 on the first four hides every value below 1.
print ffn(x, w1, [[-1, -1, -1, -1, 0, 0, 0, 0]], w2, zero4)
