# Chapter 22 operations as functions callable from C++.
def relu_m(a: tensor[?x?]) = relu(a)
def row_sums(a: tensor[?x?]) = row_sum(a)
def col_maxes(a: tensor[?x?]) = col_max(a)
def layer(x: tensor[4x6], w: tensor[6x3], bias: tensor[1x3]) = relu(x @ w + bias)
def center(a: tensor[5x4]) = a - col_mean(a)
