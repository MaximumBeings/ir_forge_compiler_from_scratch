def f(a: tensor[?x?], b: tensor[?x?]) = a / b
print f([[1, 2, 3]], [[1], [2]])
