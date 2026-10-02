# Every operator on two 2x2 matrices (and a scalar).
let a = [[1, 2], [3, 4]]
let b = [[10, 20], [30, 40]]
print a + b
print b - a
print a * b                        # elementwise (Hadamard)
print b / a
print a @ b                        # matrix product
print transpose(a)
print -a
print a * 2 + 1
