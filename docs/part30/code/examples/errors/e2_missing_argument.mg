# attention_sublayer takes twelve arguments. Eleven is an arity error, reported before any code exists.
def softmax(s: tensor[4x4]) = exp(s - row_max(s)) / row_sum(exp(s - row_max(s)))
def layer_norm(x: tensor[4x4], g: tensor[1x4], b: tensor[1x4]) = (x - row_mean(x)) / sqrt(row_mean((x - row_mean(x)) * (x - row_mean(x))) + 0.00001) * g + b
def head(x: tensor[4x4], wq: tensor[4x2], wk: tensor[4x2], wv: tensor[4x2], mask: tensor[4x4]) = softmax((x @ wq) @ transpose(x @ wk) * 0.7071067811865476 + mask) @ (x @ wv)
def attention(x: tensor[4x4], mask: tensor[4x4], wq1: tensor[4x2], wk1: tensor[4x2], wv1: tensor[4x2], wo1: tensor[2x4], wq2: tensor[4x2], wk2: tensor[4x2], wv2: tensor[4x2], wo2: tensor[2x4]) = head(x, wq1, wk1, wv1, mask) @ wo1 + head(x, wq2, wk2, wv2, mask) @ wo2
def attention_sublayer(x: tensor[4x4], mask: tensor[4x4], g: tensor[1x4], bt: tensor[1x4], wq1: tensor[4x2], wk1: tensor[4x2], wv1: tensor[4x2], wo1: tensor[2x4], wq2: tensor[4x2], wk2: tensor[4x2], wv2: tensor[4x2], wo2: tensor[2x4]) = x + attention(layer_norm(x, g, bt), mask, wq1, wk1, wv1, wo1, wq2, wk2, wv2, wo2)
let m = [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]
let h = [[1, 0], [0, 1], [1, 1], [0, 0]]
let g = [[1, 1, 1, 1]]
print attention_sublayer(m, m, g, g, h, h, h, [[1, 0, 0, 0], [0, 1, 0, 0]], h, h, h)
