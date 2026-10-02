# The Chapter 21 operations, as functions callable from C++.
def sub(a: tensor[?x?], b: tensor[?x?]) = a - b
def hadamard(a: tensor[?x?], b: tensor[?x?]) = a * b
def divide(a: tensor[?x?], b: tensor[?x?]) = a / b
def matmul(a: tensor[?x?], b: tensor[?x?]) = a @ b
def affine(a: tensor[?x?]) = a * 2 + 1
def gram(a: tensor[?x?]) = a @ transpose(a)
