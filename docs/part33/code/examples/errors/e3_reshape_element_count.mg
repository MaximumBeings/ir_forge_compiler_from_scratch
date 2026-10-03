# reshape keeps the numbers, so the counts must match: 8 numbers cannot fill a 4 x 3 shape (12 numbers). (The chapter reshapes 96 x 1 to 24 x 4: the same 96 numbers.)
let a = [[1], [2], [3], [4], [5], [6], [7], [8]]
print reshape(a, 4, 3)
