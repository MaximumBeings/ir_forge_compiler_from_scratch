# Division on dynamic shapes, with numbers where the order matters (a / b is not b / a).
def g(a: tensor[?x?], b: tensor[?x?]) = a / b
print g([[1, 4], [9, 3]], [[2, 8], [3, 4]])
