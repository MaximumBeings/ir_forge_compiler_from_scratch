# Transposing twice gives the original back. The shape goes 2x3 -> 3x2 -> 2x3.
let a = [[1, 2, 3], [4, 5, 6]]
print transpose(a)
print transpose(transpose(a))
