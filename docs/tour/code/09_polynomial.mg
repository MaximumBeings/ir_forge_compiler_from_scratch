# Evaluate the polynomial 1 + 2x + 3x^2 at x = 1, 2, 3 with ONE matrix product.
# Row i of the "Vandermonde" matrix is [1, x, x^2] for the i-th x; multiplying by the coefficient column [1, 2, 3] evaluates all of them at once.
let vandermonde = [[1, 1, 1], [1, 2, 4], [1, 3, 9]]
let coefficients = [[1], [2], [3]]
print vandermonde @ coefficients        # 1+2+3 = 6,  1+4+12 = 17,  1+6+27 = 34
