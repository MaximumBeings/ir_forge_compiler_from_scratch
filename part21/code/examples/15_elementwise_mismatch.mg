# The run-time shape check is not only for '+': subtract, multiply and divide each abort on a dimension mismatch,
# naming the operation. Here 1x3 minus 2x1: the 1x3 is a ?-typed parameter, so nothing broadcasts and the check runs.
def f(a: tensor[?x?], b: tensor[?x?]) = a - b
print f([[1, 2, 3]], [[1], [2]])
