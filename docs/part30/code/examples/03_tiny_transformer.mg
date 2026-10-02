# A small transformer, written in Mountain Goat. Shapes are fixed: 4 tokens, model width 4, 2 attention heads of width 2, feed-forward width 8, vocabulary 5.
# (Every def is one line, because a def is one line; the long ones are long.)

# softmax of each row, stabilised by subtracting the row maximum (Chapter 29), for the 4x4 attention scores and for the 4x5 vocabulary scores
def softmax(s: tensor[4x4]) = exp(s - row_max(s)) / row_sum(exp(s - row_max(s)))
def softmax_vocab(s: tensor[4x5]) = exp(s - row_max(s)) / row_sum(exp(s - row_max(s)))

# layer normalisation: each token (row) is shifted to mean 0 and scaled to variance 1, then rescaled by g and shifted by b (1 x 4, one per feature)
def layer_norm(x: tensor[4x4], g: tensor[1x4], b: tensor[1x4]) = (x - row_mean(x)) / sqrt(row_mean((x - row_mean(x)) * (x - row_mean(x))) + 0.00001) * g + b

# one attention head: queries, keys and values are projections of x; the mask (0 or -1e9) is added to the scores before the softmax (Chapter 29)
def head(x: tensor[4x4], wq: tensor[4x2], wk: tensor[4x2], wv: tensor[4x2], mask: tensor[4x4]) = softmax((x @ wq) @ transpose(x @ wk) * 0.7071067811865476 + mask) @ (x @ wv)

# two heads. Concatenating the heads and multiplying by one output matrix equals adding each head times its own half of that matrix (wo1 is the top half, wo2 the bottom)
def attention(x: tensor[4x4], mask: tensor[4x4], wq1: tensor[4x2], wk1: tensor[4x2], wv1: tensor[4x2], wo1: tensor[2x4], wq2: tensor[4x2], wk2: tensor[4x2], wv2: tensor[4x2], wo2: tensor[2x4]) = head(x, wq1, wk1, wv1, mask) @ wo1 + head(x, wq2, wk2, wv2, mask) @ wo2

# the position-wise feed-forward network: expand to 8 features, relu, contract back to 4
def ffn(x: tensor[4x4], w1: tensor[4x8], b1: tensor[1x8], w2: tensor[8x4], b2: tensor[1x4]) = relu(x @ w1 + b1) @ w2 + b2

# the two sublayers of a block, each with a residual connection and a layer norm applied BEFORE the sublayer ("pre-norm")
def attention_sublayer(x: tensor[4x4], mask: tensor[4x4], g: tensor[1x4], bt: tensor[1x4], wq1: tensor[4x2], wk1: tensor[4x2], wv1: tensor[4x2], wo1: tensor[2x4], wq2: tensor[4x2], wk2: tensor[4x2], wv2: tensor[4x2], wo2: tensor[2x4]) = x + attention(layer_norm(x, g, bt), mask, wq1, wk1, wv1, wo1, wq2, wk2, wv2, wo2)
def ffn_sublayer(x: tensor[4x4], g: tensor[1x4], bt: tensor[1x4], w1: tensor[4x8], b1: tensor[1x8], w2: tensor[8x4], b2: tensor[1x4]) = x + ffn(layer_norm(x, g, bt), w1, b1, w2, b2)

let emb = [[0.03, -0.65, -0.38, 0.07], [0.9, -0.66, 0.4, -0.55], [-0.01, -0.75, -0.83, -0.22], [-0.45, -0.26, 0.97, 0.07], [0.53, 0.29, 0.53, 0.56]]
let wout = [[0.52, -0.56, 0.2, -0.3, -0.24], [0.67, 0.03, -0.16, 0.17, 0.46], [0.69, 0.59, 0.59, 0.28, 0.41], [0.13, -0.18, -0.23, -0.48, 0.52]]
let gf = [[0.98, 0.99, 1.1, 0.93]]
let bf = [[-0.06, 0.09, 0.05, -0.02]]
let g1_1 = [[1.06, 1.05, 1.09, 0.91]]
let bt1_1 = [[-0.04, 0.05, -0.05, 0.02]]
let wq1_1 = [[-0.73, 0.73], [-0.29, -0.71], [-0.09, 0.66], [0.12, -0.61]]
let wk1_1 = [[0.11, -0.4], [-0.01, -0.42], [-0.04, -0.15], [0.6, -0.12]]
let wv1_1 = [[-0.23, -0.19], [-0.73, -0.54], [0.04, 0.31], [-0.64, -0.16]]
let wo1_1 = [[0.44, -0.41, -0.25, -0.43], [-0.32, -0.31, 0.62, -0.74]]
let wq2_1 = [[0.24, -0.16], [0.28, 0.37], [0.7, -0.43], [0.54, 0.75]]
let wk2_1 = [[0.45, -0.11], [0.28, 0.49], [-0.55, -0.35], [-0.58, 0.58]]
let wv2_1 = [[0.4, -0.47], [-0.58, -0.33], [0.48, -0.45], [0.1, 0.34]]
let wo2_1 = [[-0.48, 0.78, -0.4, -0.11], [0.41, 0.58, 0.63, 0.76]]
let g2_1 = [[0.98, 0.99, 0.93, 0.99]]
let bt2_1 = [[-0.05, 0.1, 0.03, 0.02]]
let w1_1 = [[-0.41, -0.07, 0.46, -0.67, -0.04, -0.56, -0.41, 0.71], [0.18, 0.78, -0.04, 0.48, 0.39, -0.19, -0.03, 0.04], [-0.64, 0.15, -0.24, -0.57, 0.45, 0.34, -0.09, 0.33], [-0.65, 0.74, 0.08, 0.38, 0.13, 0.22, 0.45, -0.5]]
let b1_1 = [[-0.04, -0.04, 0.04, -0.04, 0.01, -0.02, -0.04, -0.01]]
let w2_1 = [[0.11, -0.02, 0.17, -0.13], [-0.59, -0.39, -0.74, 0.76], [-0.62, -0.2, 0.23, -0.24], [0.08, -0.23, 0.1, -0.04], [-0.54, 0.18, -0.52, 0.09], [-0.33, 0.6, 0.54, 0.55], [0.63, 0.15, 0.06, -0.53], [0.25, 0.3, -0.38, -0.63]]
let b2_1 = [[0.06, -0.06, -0.02, -0.03]]
let g1_2 = [[1.07, 0.93, 0.95, 0.94]]
let bt1_2 = [[0, -0.02, 0, 0]]
let wq1_2 = [[-0.24, 0.04], [-0.61, 0.03], [0.17, 0.37], [0.09, -0.25]]
let wk1_2 = [[0.48, 0.15], [-0.37, 0.27], [0.08, 0.46], [0.62, 0.62]]
let wv1_2 = [[-0.69, 0.48], [0.65, 0.23], [-0.54, -0.32], [-0.53, -0.34]]
let wo1_2 = [[0.55, 0.06, -0.74, -0.47], [-0.77, -0.23, 0.19, 0.03]]
let wq2_2 = [[0.07, -0.55], [0.52, -0.75], [-0.76, -0.19], [0.19, -0.77]]
let wk2_2 = [[0.2, 0.66], [-0.2, 0.37], [-0.17, 0.77], [0.16, -0.62]]
let wv2_2 = [[-0.45, 0.48], [0.59, 0.38], [-0.78, 0.38], [-0.13, -0.22]]
let wo2_2 = [[-0.47, -0.51, -0.68, -0.62], [-0.55, 0.46, -0.74, 0.47]]
let g2_2 = [[1.02, 0.98, 0.95, 0.94]]
let bt2_2 = [[0.02, -0.03, 0.02, 0.09]]
let w1_2 = [[-0.2, -0.5, -0.32, -0.71, -0.57, -0.78, 0.62, 0.73], [0.2, 0.73, 0.21, -0.74, -0.24, -0.57, -0.63, -0.48], [-0.67, -0.76, 0.71, 0.67, 0.65, 0.58, -0.56, -0.53], [-0.69, 0.24, 0.38, -0.64, -0.54, -0.65, -0.61, -0.76]]
let b1_2 = [[0.05, 0.09, -0.09, 0.03, -0.08, -0.01, -0.04, -0.1]]
let w2_2 = [[0.62, 0.41, 0.02, -0.53], [0.42, 0.61, 0, 0.6], [0.38, -0.42, -0.72, 0.17], [0.6, 0.01, 0.29, 0.78], [0.17, -0.01, 0.14, 0.63], [-0.73, 0.61, -0.63, 0.03], [0.13, -0.78, -0.18, -0.04], [-0.49, 0.01, 0.44, -0.23]]
let b2_2 = [[0.04, 0.08, 0.03, 0.04]]
let mask = [[0, -1000000000, -1000000000, -1000000000], [0, 0, -1000000000, -1000000000], [0, 0, 0, -1000000000], [0, 0, 0, 0]]
let onehot = [[0, 1, 0, 0, 0], [0, 0, 0, 1, 0], [1, 0, 0, 0, 0], [0, 0, 1, 0, 0]]       # the token ids [1, 3, 0, 2] as one-hot rows
let positions = [[0, 1, 0, 1], [0.8415, 0.5403, 0.01, 1], [0.9093, -0.4161, 0.02, 0.9998], [0.1411, -0.99, 0.03, 0.9996]]
let x0 = onehot @ emb + positions
let a1 = attention_sublayer(x0, mask, g1_1, bt1_1, wq1_1, wk1_1, wv1_1, wo1_1, wq2_1, wk2_1, wv2_1, wo2_1)
let y1 = ffn_sublayer(a1, g2_1, bt2_1, w1_1, b1_1, w2_1, b2_1)
let a2 = attention_sublayer(y1, mask, g1_2, bt1_2, wq1_2, wk1_2, wv1_2, wo1_2, wq2_2, wk2_2, wv2_2, wo2_2)
let y2 = ffn_sublayer(a2, g2_2, bt2_2, w1_2, b1_2, w2_2, b2_2)
let probs = softmax_vocab(layer_norm(y2, gf, bf) @ wout)
print x0
print y1
print y2
print probs
