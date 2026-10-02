# Precedence: unary minus binds tightest, then * / @ (left to right), then + -.
let a = [[1, 2], [3, 4]]
let b = [[1, 0], [0, 1]]
print a + a * a
print (a + a) * a
print a - b @ a
print -a + 10
let k = 2 + 3 * 4
print a * k
