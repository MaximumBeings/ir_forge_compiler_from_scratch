# Functions are built from other functions defined ABOVE them. The shapes flow through every call and are checked at each one.
def double(a: tensor[2x2]) = a * 2
def add_identity(a: tensor[2x2]) = a + [[1, 0], [0, 1]]
def double_then_add_identity(a: tensor[2x2]) = add_identity(double(a))
def square(a: tensor[2x2]) = a @ a
let m = [[1, 2], [3, 4]]
print double_then_add_identity(m)               # 2m + I = [[3, 4], [6, 9]]
print square(double_then_add_identity(m))       # [[3,4],[6,9]] squared as a matrix product: [[33, 48], [72, 105]]
print double(square(m)) - square(double(m))     # (2*m^2) - (2m)^2 = 2m^2 - 4m^2 = -2m^2 = [[-14, -20], [-30, -44]]
