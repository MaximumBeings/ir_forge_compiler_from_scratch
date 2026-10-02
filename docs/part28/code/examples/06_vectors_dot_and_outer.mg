# Rank 1 tensors exist too (reshape a one-row matrix to a single dimension). Three contractions:
let u = reshape([[1, 2, 3]], 3)
let v = reshape([[4, 5, 6, 7]], 4)
print contract(u, (0), u, (0))     # dot product: every axis summed away, 1+4+9 = 14 (returned as a 1x1 matrix)
print contract(u, (), v, ())       # outer product: nothing summed, a 3x4 table of products
print contract(reshape([[1, 2, 3, 4]], 4), (0), reshape([[1, 0, 1], [0, 1, 1], [1, 1, 0], [2, 0, 1]], 4, 3), (0))   # vector times matrix
