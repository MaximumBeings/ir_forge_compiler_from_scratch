# reshape needs every size known now. batch has a '?' row count, so the compiler cannot tell whether it has the right number of elements.
def flatten(batch: tensor[?x4]) = reshape(batch, 2, 2, 2)
print flatten([[1, 2, 3, 4]])
