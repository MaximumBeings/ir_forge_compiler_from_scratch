# A 3x5 times 5x2 matrix product: no dimension is a multiple of the tile sizes used in the tests, so tiled loops must stop short at the edges.
def mm(a: tensor[?x?], b: tensor[?x?]) = a @ b
print mm([[1, 2, 3, 4, 5], [6, 7, 8, 9, 10], [11, 12, 13, 14, 15]], [[1, 0], [0, 1], [1, 1], [2, 0], [0, 2]])
