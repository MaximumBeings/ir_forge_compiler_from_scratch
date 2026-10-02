# Shapes that match only at compile time of the CALLER but not at run time: 2x3 + 3x2 through a ?x? function.
def add(a: tensor[?x?], b: tensor[?x?]) = a + b
print add([[1, 2, 3], [4, 5, 6]], [[1, 2], [3, 4], [5, 6]])
