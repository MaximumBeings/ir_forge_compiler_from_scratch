# Scalar operations need no run-time shape check (there is no second matrix), so they work on any shape.
def affine(a: tensor[?x?]) = a * 2 + 1
print affine([[1, 2, 3]])
print affine([[1], [2]])
print affine([[0, 0], [0, 0], [0, 0]])
