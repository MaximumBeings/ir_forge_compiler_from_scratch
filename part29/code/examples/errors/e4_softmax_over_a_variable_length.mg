# A softmax over a sequence of any length would need x - row_max(x) with a '?' row count, and a '?' size is never stretched (Chapter 22):
# the compiler refuses it. Attention in this chapter is for a fixed sequence length.
def softmax(x: tensor[?x3]) = exp(x - row_max(x)) / row_sum(exp(x - row_max(x)))
print softmax([[1, 2, 3]])
