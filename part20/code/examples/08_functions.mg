# Functions with fixed (static) shapes, called from the main program and from each other.
def double(a: tensor[2x2]) = a + a
def quad(a: tensor[2x2]) = double(double(a))
let m = [[1, 2], [3, 4]]
print double(m)
print quad(m)
