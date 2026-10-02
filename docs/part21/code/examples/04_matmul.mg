# Matrix product: (2x3) @ (3x2) gives (2x2). Entry (i,j) = sum over k of a[i,k] * b[k,j].
let a = [[1, 2, 3], [4, 5, 6]]
let b = [[7, 8], [9, 10], [11, 12]]
print a @ b
print b @ a
