# The ORDER of the paired axes matters: the first axis listed for A meets the first listed for B. Here A's axes 2 and 1 pair with B's axes 0 and 1.
# A is 2x3x4 and B is 4x3x2, so the pairs have sizes 4=4 and 3=3. Listed the other way, (1, 2) against (0, 1), the sizes would not match.
let a = reshape([[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], [0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1]], 2, 3, 4)
let b = reshape([[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]], 4, 3, 2)
print contract(a, (2, 1), b, (0, 1))      # a 2x2 result
