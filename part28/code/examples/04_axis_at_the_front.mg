# The contracted axis is the FIRST axis of A, so A must be permuted before it can be flattened: this is the case that makes the language
# move data. A is 2x3x4, B is 2x5; summing over A's axis 0 against B's axis 0 leaves A's axes 1, 2 and B's axis 1: a 3x4x5 result.
let a = reshape([[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], [-1, -2, -3, -4, -5, -6, -7, -8, -9, -10, -11, -12]], 2, 3, 4)
let b = [[1, 0, 2, 0, 3], [0, 1, 0, 2, 0]]
print contract(a, (0), b, (0))
