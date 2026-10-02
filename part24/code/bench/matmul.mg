# The function being measured: a matrix product, once with dynamic sizes and once with a fixed 256x256 shape.
def mm_dyn(a: tensor[?x?], b: tensor[?x?]) = a @ b
def mm_256(a: tensor[256x256], b: tensor[256x256]) = a @ b
