# Dynamic shapes: one function over tensor[?x?], called with two different sizes.
def addt(a: tensor[?x?], b: tensor[?x?]) = transpose(a + b)
print addt([[1, 2, 3], [4, 5, 6]], [[10, 20, 30], [40, 50, 60]])
print addt([[1], [2], [3]], [[0.5], [0.5], [0.5]])
