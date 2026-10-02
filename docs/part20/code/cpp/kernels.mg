# Mountain Goat functions to be called from C++.
def add(a: tensor[?x?], b: tensor[?x?]) = a + b
def add_t(a: tensor[?x?], b: tensor[?x?]) = transpose(a + b)
def scale2(a: tensor[?x?]) = a + a
def rot(a: tensor[2x3]) = transpose(a)
