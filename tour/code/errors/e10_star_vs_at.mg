# '*' multiplies matching elements; it does not do the matrix product. 2x3 and 3x2 do not match, so this is an error: you meant '@'.
let a = [[1, 2, 3], [4, 5, 6]]
let b = [[1, 2], [3, 4], [5, 6]]
print a * b
