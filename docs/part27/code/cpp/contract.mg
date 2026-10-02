# The entire arithmetic of a tensor contraction, as one Mountain Goat function.
# Any contraction can be rearranged into a single matrix product (see tensor.h): the sum over the contracted axes becomes the sum over
# the inner dimension of the product. The row and column counts are dynamic (?), so one compiled function serves every contraction.
def gemm(a: tensor[?x?], b: tensor[?x?]) = a @ b
