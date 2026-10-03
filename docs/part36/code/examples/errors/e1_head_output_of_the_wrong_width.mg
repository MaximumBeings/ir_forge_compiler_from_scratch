# A head of width 4 produces a 6 x 4 result; its output matrix must be 4 x 8 to bring it back to the model width 8. A 2 x 8 matrix does not fit, and the compiler says so.
let o = [[1, 2, 3, 4], [1, 2, 3, 4], [1, 2, 3, 4], [1, 2, 3, 4], [1, 2, 3, 4], [1, 2, 3, 4]]
let wo = [[1, 0, 0, 0, 0, 0, 0, 0], [0, 1, 0, 0, 0, 0, 0, 0]]
print o @ wo
