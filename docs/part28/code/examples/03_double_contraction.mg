# A double contraction: [2,3,4] x [3,4,5], summing over A's axes 1 and 2 against B's axes 0 and 1.
# The data is the appendix's: A[i] = (i % 7) - 3 and B[i] = (i % 5) - 2, numbered in row-major order. Each literal is a matrix whose rows are
# the first axis of the tensor; reshape then views it with its real shape.
let a = reshape([[-3, -2, -1, 0, 1, 2, 3, -3, -2, -1, 0, 1], [2, 3, -3, -2, -1, 0, 1, 2, 3, -3, -2, -1]], 2, 3, 4)
let b = reshape([[-2, -1, 0, 1, 2, -2, -1, 0, 1, 2, -2, -1, 0, 1, 2, -2, -1, 0, 1, 2], [-2, -1, 0, 1, 2, -2, -1, 0, 1, 2, -2, -1, 0, 1, 2, -2, -1, 0, 1, 2], [-2, -1, 0, 1, 2, -2, -1, 0, 1, 2, -2, -1, 0, 1, 2, -2, -1, 0, 1, 2]], 3, 4, 5)
print contract(a, (1, 2), b, (0, 1))      # (2) free axis of A, (5) free axis of B: a 2x5 result; expected [[10, 5, 0, -5, -10], [2, 1, 0, -1, -2]]
