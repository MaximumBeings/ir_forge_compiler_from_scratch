# The same product with sizes known only at run time (the shape Chapter 23 and 24 benchmarked).
def mm_dyn(a: tensor[?x?], b: tensor[?x?]) = a @ b
