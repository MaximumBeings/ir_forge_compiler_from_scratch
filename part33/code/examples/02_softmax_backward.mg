# The one new piece of calculus in this chapter: how the loss changes when the scores of a softmax change.
# If L = (d . softmax(s)) for a fixed vector d, the derivative with respect to s_i is  a_i * (d_i - sum_j a_j d_j)  where a = softmax(s).
# The first line prints that formula; the second computes the same derivatives by brute force (nudge each score by 0.01 up and down and watch L change).
def softmax(s: tensor[1x3]) = exp(s - row_max(s)) / row_sum(exp(s - row_max(s)))
def loss(s: tensor[1x3], d: tensor[1x3]) = row_sum(d * softmax(s))
def backward(s: tensor[1x3], d: tensor[1x3]) = softmax(s) * (d - row_sum(softmax(s) * d))
let s = [[0.5, -1, 2]]
let d = [[3, -2, 1]]
print backward(s, d)
print (loss(s + [[0.01, 0, 0]], d) - loss(s - [[0.01, 0, 0]], d)) / 0.02       # nudge s_0
print (loss(s + [[0, 0.01, 0]], d) - loss(s - [[0, 0.01, 0]], d)) / 0.02       # nudge s_1
print (loss(s + [[0, 0, 0.01]], d) - loss(s - [[0, 0, 0.01]], d)) / 0.02       # nudge s_2
