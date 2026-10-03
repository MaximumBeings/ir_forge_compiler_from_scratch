# The function being measured: a matrix product with sizes known only at run time.
def mm_dyn(a: tensor[?x?], b: tensor[?x?]) = a @ b
