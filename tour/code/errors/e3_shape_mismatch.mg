# 2x3 and 3x2 cannot be added: the dimensions differ and neither is 1, so broadcasting cannot help
let a = [[1, 2, 3], [4, 5, 6]]
let b = [[1, 2], [3, 4], [5, 6]]
print a + b
