# Row and column vectors through ONE dynamic function: the same compiled code handles 1x4 and 4x1.
def flip(a: tensor[?x?], b: tensor[?x?]) = transpose(a + b)
print flip([[1, 2, 3, 4]], [[10, 10, 10, 10]])
print flip([[1], [2], [3], [4]], [[5], [5], [5], [5]])
