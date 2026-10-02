# One compiled matmul for any compatible sizes. The inner dimensions are checked at run time.
def mm(a: tensor[?x?], b: tensor[?x?]) = a @ b
print mm([[1, 2, 3], [4, 5, 6]], [[1], [1], [1]])
print mm([[1, 2]], [[3, 4], [5, 6]])
print mm([[2]], [[21]])
