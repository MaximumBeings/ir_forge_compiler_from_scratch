# Negation, on its own: static and dynamic shapes. (-(-a) = a cannot tell a real negation from a no-op; these can.)
def h(a: tensor[?x?]) = -a
print h([[1, -2, 3]])
print -[[0.5, -4]]
print h([[7], [-8]])
