# Broadcasting works whichever side the small operand is on, and for non-commutative operators the order is kept.
let a = [[1, 2, 3], [4, 5, 6]]
let row = [[10, 20, 30]]
print row + a                     # the 1x3 row is on the LEFT
print row - a                     # 10-1, 20-2, ...: left minus right, not the reverse
print [[100], [200]] - a          # a 2x1 column on the left
print [[2]] * a
