# Which operator goes first? '@', '*' and '/' bind tighter than '+' and '-'; unary minus binds tightest; parentheses override. Same level goes left to right.
let a = [[1, 2], [3, 4]]
let b = [[1, 0], [0, 2]]
print a + a * b              # a * b first (elementwise), then add: [[1,2],[3,4]] + [[1,0],[0,8]] = [[2, 2], [3, 12]]
print (a + a) * b            # parentheses first: [[2,4],[6,8]] * [[1,0],[0,2]] = [[2, 0], [0, 16]]
print a @ b + a              # the product first: [[1,4],[3,8]] + [[1,2],[3,4]] = [[2, 6], [6, 12]]
print a @ (b + a)            # [[1,2],[3,4]] @ [[2,2],[3,6]] = [[8, 14], [18, 30]]
print a - a - a              # left to right: (a - a) - a = -a
print -a * b                 # unary minus first: (-a) * b = [[-1, 0], [0, -8]]
print a @ b @ a              # left to right: (a @ b) @ a = [[1,4],[3,8]] @ [[1,2],[3,4]] = [[13, 18], [27, 38]]
