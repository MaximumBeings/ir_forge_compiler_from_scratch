# A comparison that depends on NaN behaving like NaN. softmax_naive of huge scores is NaN (Chapter 29: infinity / infinity); a NaN is not >= itself, so ge(p, p) must print 0.
# With the flags 'no NaNs' (nnan) the optimizer is allowed to assume p is never NaN, and then p >= p is true.
def softmax_naive(x: tensor[1x3]) = exp(x) / row_sum(exp(x))
def same(p: tensor[1x3]) = ge(p, p)
print same(softmax_naive([[1000, 1001, 1002]]))
