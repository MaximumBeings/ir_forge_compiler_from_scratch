# A scalar can stand on either side of an operator, and the order matters for - and /.
let a = [[1, 2], [4, 8]]
print a - 1                  # each element minus 1
print 10 - a                 # 10 minus each element (the scalar is on the LEFT)
print a / 2                  # each element over 2
print 16 / a                 # 16 over each element
print 2 * a + 1              # scalars on the left work for * and + too
print -(a - 4)               # unary minus applies to a whole expression
