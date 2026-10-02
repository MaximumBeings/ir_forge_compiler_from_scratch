# A rank 4 result: A is 2x2x3 and B is 3x2x2; contracting only the 3's (A's axis 2 with B's axis 0) leaves A's two free axes and B's two: 2x2x2x2.
let a = reshape([[1, 2, 3, 4, 5, 6], [7, 8, 9, 10, 11, 12]], 2, 2, 3)
let b = reshape([[1, 0, 2, 1], [0, 1, 1, 2], [1, 1, 0, 0]], 3, 2, 2)
print contract(a, (2), b, (0))
