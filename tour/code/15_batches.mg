# One function, any number of samples: rows are samples, so a '?' in the row count means "any batch size".
def scale(batch: tensor[?x2], w: tensor[2x2]) = batch @ w
print scale([[1, 1]], [[1, 0], [0, 2]])                                  # a batch of one
print scale([[1, 1], [2, 2], [3, 3]], [[1, 0], [0, 2]])                  # a batch of three: the same compiled function

# Adding a bias to every row needs the bias repeated once per sample. A '?' size is never broadcast (it is not known when compiling),
# but a matrix product can do the repeating: a column of ones (one 1 per sample) times the 1x2 bias is a ?x2 matrix of copies of the bias.
def scale_and_shift(batch: tensor[?x2], ones: tensor[?x1], w: tensor[2x2], b: tensor[1x2]) = batch @ w + ones @ b
print scale_and_shift([[1, 1], [2, 2], [3, 3]], [[1], [1], [1]], [[1, 0], [0, 2]], [[10, 20]])
